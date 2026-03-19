import os
import re
import shutil
import subprocess
import yaml
import time
import stat
from pathlib import Path
import markdown
from jinja2 import Environment, FileSystemLoader
from markdown.extensions.toc import slugify
import datetime

# 加载配置
with open('config.yaml', encoding='utf-8') as f:
    config = yaml.safe_load(f)

# 路径设置
BASE_DIR = Path(__file__).parent
NOTES_DIR = BASE_DIR / config['notes_dir']
TEMPLATES_DIR = BASE_DIR / config['templates_dir']
DIST_DIR = BASE_DIR / config['dist_dir']
IMAGES_DIR = BASE_DIR / config['images_dir']  # 图片目录

# 创建Jinja环境
env = Environment(loader=FileSystemLoader(TEMPLATES_DIR))

def remove_readonly(func, path, excinfo):
    """解决Windows文件权限问题"""
    os.chmod(path, stat.S_IWRITE)
    func(path)

def extract_toc(md_content):
    """从Markdown内容提取目录结构"""
    toc = []
    for line in md_content.split('\n'):
        if line.startswith('#'):
            level = len(line.split(' ')[0])
            title = line.replace('#', '').strip()
            anchor = slugify(title, '-')
            toc.append({'level': level, 'title': title, 'anchor': anchor})
    return toc

def generate_note_page(note_path):
    """生成单个笔记页面"""
    with open(note_path, 'r', encoding='utf-8') as f:
        md_content = f.read()
    
    # 转换Markdown为HTML
    html_content = markdown.markdown(
        md_content, 
        extensions=['fenced_code', 'tables', 'toc']
    )
    
    # 提取目录
    toc = extract_toc(md_content)
    
    # 渲染模板
    template = env.get_template('note_template.html')
    note_name = note_path.stem
    return template.render(
        title=note_name.replace('_', ' ').title(),
        content=html_content,
        toc=toc,
        notes_dir=config['notes_dir'],
        now=datetime.datetime.now()
    )

def build_site():
    """构建整个站点"""
    # 清理并创建dist目录
    if DIST_DIR.exists():
        # 尝试删除.git目录（如果存在）
        git_dir = DIST_DIR / '.git'
        if git_dir.exists():
            shutil.rmtree(git_dir, onerror=remove_readonly)
        
        # 删除整个dist目录
        for _ in range(3):  # 最多尝试3次
            try:
                shutil.rmtree(DIST_DIR, onerror=remove_readonly)
                break
            except PermissionError:
                print("等待文件释放...")
                time.sleep(1)
        else:
            print("无法删除dist目录，请手动删除后重试")
            return
    
    DIST_DIR.mkdir()
    
    # 处理所有Markdown笔记
    notes = []
    for md_file in NOTES_DIR.glob('*.md'):
        print(f"Processing: {md_file.name}")
        
        # 生成HTML内容
        html_content = generate_note_page(md_file)
        
        # 保存HTML文件
        html_file = DIST_DIR / f"{md_file.stem}.html"
        with open(html_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        notes.append({
            'title': md_file.stem.replace('_', ' ').title(),
            'link': f"{md_file.stem}.html"
        })
    
    # 生成首页
    index_template = env.get_template('index_template.html')
    with open(DIST_DIR / 'index.html', 'w', encoding='utf-8') as f:
        f.write(index_template.render(notes=notes, now=datetime.datetime.now()))
    
    # 复制静态资源
    if (TEMPLATES_DIR / 'static').exists():
        shutil.copytree(TEMPLATES_DIR / 'static', DIST_DIR / 'static', dirs_exist_ok=True)
    
    # 复制图片目录到dist
    if IMAGES_DIR.exists():
        shutil.copytree(IMAGES_DIR, DIST_DIR / 'images', dirs_exist_ok=True)
    
    # 复制elab图标
    if (TEMPLATES_DIR / 'elab.png').exists():
        shutil.copy(TEMPLATES_DIR / 'elab.png', DIST_DIR / 'elab.png')
    
    print("Site built successfully!")
    
def git_push():
    """推送到GitHub Pages"""
    if not config.get('github_pages_repo'):
        raise ValueError("config.yaml 里缺少 github_pages_repo")

    pages_branch = config.get('github_pages_branch', 'gh-pages')

    os.chdir(DIST_DIR)
    subprocess.run(['git', 'init'], check=True)
    subprocess.run(['git', 'add', '.'], check=True)

    # Allow first deploy and repeated deploys.
    commit = subprocess.run(
        ['git', 'commit', '-m', 'Update site'],
        check=False,
        capture_output=True,
        text=True,
    )
    if commit.returncode != 0 and "nothing to commit" not in (commit.stdout + commit.stderr):
        raise RuntimeError(commit.stderr or commit.stdout)

    subprocess.run(['git', 'branch', '-M', pages_branch], check=True)

    has_origin = subprocess.run(
        ['git', 'remote', 'get-url', 'origin'],
        check=False,
        capture_output=True,
        text=True,
    )
    if has_origin.returncode == 0:
        subprocess.run(['git', 'remote', 'set-url', 'origin', config['github_pages_repo']], check=True)
    else:
        subprocess.run(['git', 'remote', 'add', 'origin', config['github_pages_repo']], check=True)

    subprocess.run(['git', 'push', '-u', 'origin', pages_branch, '-f'], check=True)
    print("Pushed to GitHub Pages!")

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Course Notes Builder')
    parser.add_argument('--build', action='store_true', help='Build the site')
    parser.add_argument('--deploy', action='store_true', help='Deploy to GitHub Pages')
    
    args = parser.parse_args()
    
    if args.build:
        build_site()
    
    if args.deploy:
        build_site()
        git_push()