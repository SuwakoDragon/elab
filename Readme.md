这个仓库用来把课程笔记从 Markdown 生成静态网页，并发布到 GitHub Pages。

日常维护时可以把它理解成两条线：main 放源码，gh-pages 放网页成品。你平时改的内容（md、模板、脚本、配置）都在 main；浏览器真正访问到的 html、css、图片是在 gh-pages，由构建脚本自动推送过去。

第一次使用先安装依赖：

c:/Users/Dragon/Desktop/demo/.venv/Scripts/python.exe -m pip install -r requirements.txt

平时更新网页只要一条命令：

c:/Users/Dragon/Desktop/demo/.venv/Scripts/python.exe build.py --deploy

这条命令会自动做三件事：先清理并重新构建 dist，再把内容提交到 gh-pages，最后推送到远端仓库。也就是说你只要专心改 main 里的源码，发布交给脚本。

如果只想本地预览构建结果，不想发布，可以用：

c:/Users/Dragon/Desktop/demo/.venv/Scripts/python.exe build.py --build

仓库地址是 https://github.com/SuwakoDragon/elab.git。Pages 建议在仓库设置里固定为 gh-pages 分支的根目录（root）。

目录结构保持下面这样就够用：

notes/ 保存课程笔记 markdown
templates/ 保存页面模板和静态样式
images/ 保存 markdown 引用图片
dist/ 构建输出目录（发布分支内容来源）
build.py 构建与发布脚本
config.yaml 构建配置
requirements.txt Python 依赖