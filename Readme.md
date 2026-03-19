纯AI 无人工参与

python build.py --build
按需求修改好模版样式后由md生成html

python build.py --deploy
发到github仓库

pip install -r requirements.txt

项目结构
├── notes/                  # Markdown笔记目录
├── templates/              # HTML模板
├── images/                   # md中图片
├── dist/                   # 编译后的静态文件
├── build.py                # 主构建脚本
├── requirements.txt        # Python依赖
├── Readme.md               # 唯一人工
└── config.yaml             # 配置文件  