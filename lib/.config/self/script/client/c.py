#!/home/clay/.venv/bin/python

from remote import RemotePostAPI, RemoteFileAPI, RemotePageAPI, RemoteRootAPI, AuthAPI
from typing import List, Union, Optional, Dict, Any, Tuple
from local import DocsScanner, Post, Page, DocsMaker
from urllib.parse import unquote
from datetime import timedelta
from pathlib import Path
from local import log
import time
import argparse
import yaml
import sys
import os
import re


class MainWorker:

    def __init__(self, base_url, api_key):
        self.base_url = base_url
        self.api_key = api_key
        self.config = {"base_url": base_url, "api_key": api_key}
        # api
        self.auth_api = AuthAPI(**self.config)
        self.post_api = RemotePostAPI(**self.config)
        self.file_api = RemoteFileAPI(**self.config)
        self.page_api = RemotePageAPI(**self.config)
        self.root_api = RemoteRootAPI(**self.config)

        # 数据
        self.posts = []
        self.pages = []

    def docs_to_data(self, docs):
        scanner = DocsScanner(docs_root=docs)
        self.posts, self.pages = scanner.scan_directory()
        return self.posts, self.pages

    def data_to_docs(self, data: Dict[str, Any], save_dir="docs"):
        try:
            _ = data.pop("id", "")
            _ = data.pop("like", "")
            _ = data.pop("updated_at", "")
            _ = data.pop("created_at", "")

            category = data.get("category", "")
            tag = data.get("tag", "")
            if category:
                save_dir = f"{save_dir}/{category}"
                if tag:
                    save_dir = f"{save_dir}/{tag}"

            filename = data.get("title")
            content = data.pop("content", "")

            # 提取其他数据作为元数据
            metadata = {k: v for k, v in data.items()}

            # 构建Markdown内容
            markdown_parts = []

            # 添加YAML front matter元数据, 将元数据转换为YAML格式
            yaml_metadata = yaml.dump(
                metadata, default_flow_style=False, allow_unicode=True
            )
            markdown_parts.append("---")
            markdown_parts.append(yaml_metadata)
            markdown_parts.append("---")
            markdown_parts.append(content)

            # 合并所有部分
            markdown_content = "\n".join(markdown_parts)

            if not os.path.exists(save_dir):
                os.makedirs(save_dir)

            with open(f"{save_dir}/{filename}.md", "w", encoding="utf-8") as f:
                f.write(markdown_content)

            return {"save": "success"}

        except Exception as e:
            raise e

    def upload_and_replace(self, item: Union[Post, Page]):
        """用来上传"""
        attach = getattr(item, "attach")
        if not attach:
            return item

        content = item.content

        for x in attach:
            attach_path = x.get("absolute")
            upload_result = self.file_api.upload_single(attach_path)
            # 原始文件名
            origin = x.get("origin", None)
            # 上传状态
            upload_success = upload_result.get("success", False)
            # 压缩状态
            compressed = upload_result.get("compressed", False)
            # 未压缩图片地址
            img_url = upload_result.get("url", None)
            # 缩图片地址
            compressed_url = upload_result.get("compressed_url", None)
            # 替换内容中的附件为远程地址
            if upload_success and compressed:
                content = content.replace(origin, compressed_url)
            if upload_success and not compressed:
                content = content.replace(origin, img_url)
            if not upload_success:
                log.error("UPLOAD", "失败", attach_path=attach_path**upload_result)

        item.content = content
        return item

    def download_and_replace(
        self, item: Dict, base_save_dir: str, static_dir=".static"
    ):
        """
        下载内容中的所有静态资源并替换为本地路径

        Args:
            content: Markdown 内容
            base_save_dir: 保存目录的基础路径

        Returns:
            Tuple[替换后的内容, 下载的文件列表]
        """
        content = item.get("content", "")

        static_resources = self._get_static_file(content)
        downloaded_files = []

        # 使用 pathlib 处理路径
        base_path = Path(base_save_dir)

        for resource_path in static_resources:
            try:
                # 提取文件名
                filename = os.path.basename(resource_path)

                # 构建本地保存路径
                local_static_dir = base_path / ".static"
                local_static_dir.mkdir(parents=True, exist_ok=True)

                # 远程文件的 /static/ 给删除
                fixed_path = resource_path.replace("/static/", "")
                # 如果是压缩后的文件,则下载原始文件
                if fixed_path.startswith("compressed"):
                    fixed_path = fixed_path.replace("compressed", "uploads")

                # 本地保存的地址,保留结构
                local_file_path = local_static_dir / filename

                # 假设你的 file_api 有 download 方法
                download_success = self.file_api.download_single(
                    fixed_path, str(local_file_path)
                )
                if download_success:
                    # 替换内容中的远程路径为本地相对路径
                    abs_local_file_path = str(local_file_path.resolve())
                    content = content.replace(resource_path, abs_local_file_path)

                    # 如果路径在 Markdown 链接或图片中带标题，也需要处理
                    patterns_to_replace = [
                        f'({resource_path} "[^"]*")',  # 带标题的情况
                        f"({resource_path})",  # 不带标题的情况
                    ]

                    for pattern in patterns_to_replace:
                        content = re.sub(pattern, f"({abs_local_file_path})", content)

                    downloaded_files.append(str(local_file_path))
                else:
                    log.error(
                        "DOWNLOAD",
                        "失败",
                        download_success,
                        attach_path=resource_path,
                        function=sys._getframe(),
                    )

            except Exception as e:
                log.error("DOWNLOAD", "失败", attach_path=resource_path, detail=str(e))

        item["content"] = content
        return item
    def _get_static_file(self, md_content: str, unique: bool = True) -> List[str]:
        """
        从 Markdown 内容中提取所有以 /static/ 开头的静态资源路径

        Args:
            md_content: Markdown 文本内容
            unique: 是否返回去重后的结果，默认为 True

        Returns:
            静态资源路径列表
        """
        # 更宽松的正则表达式，匹配所有 /static/ 开头的路径
        patterns = [
            # 匹配所有 /static/ 开头的路径，包含括号
            r'/static/[^\s<>"\'\)]*(?:\([^)]*\))?[^\s<>"\'\)]*'
        ]

        resources = []

        for pattern in patterns:
            matches = re.findall(pattern, md_content, re.IGNORECASE)
            for match in matches:
                # 清理路径，移除 URL 编码、查询参数和可能的标题文本
                clean_path = match.split("?")[0].split("#")[0].strip()
                clean_path = clean_path.split('"')[0].strip()  # 移除标题文本
                clean_path = unquote(clean_path)  # URL 解码

                # 进一步验证这确实是一个文件路径（包含文件名）
                if (clean_path and
                    clean_path.startswith("/static/") and
                    '/' in clean_path[8:] and  # 确保有子路径
                    '.' in clean_path.split('/')[-1]):  # 确保文件名中有点（可能是后缀）
                    resources.append(clean_path)

        # 去重处理
        if unique:
            seen = set()
            unique_resources = []
            for resource in resources:
                if resource not in seen:
                    seen.add(resource)
                    unique_resources.append(resource)
            return unique_resources

        return resources

    def example_maker(self, docs="docs"):
        """创建示例文档"""
        docs = Path(docs)
        if docs.exists():
            log.warning("EXAMPLE", "默认路径docs已存在,操作取消")
            return
        template = DocsMaker(docs)
        template.example_maker()
        log.success("EXAMPLE", "示例文档创建完成", docs=docs)

    def template_maker(self, docs="docs"):
        """创建模板文档"""
        docs = Path(docs)
        template = DocsMaker(docs)
        template.template_maker()
        log.success("TEMPLATE", "模板文件创建完成", docs=docs)

    def conflict(self, mode="show", docs="docs"):
        """
        存在三种情况：
            1. 远程数据库有 本地无 属于多余的 多余的要么删除，要么拉取（仅仅拉取多余的，不影响本地，和pull全部拉取不同）
            2. 本地数据库有 远程无 即将新建的（新建的可以直接忽略，一次push可以解决）

            delete就是删除远程仅有的
            pull 就是拉取远程仅有的
        """
        # 远程数据库
        remote_posts = set(self.post_api.get_all_title())
        remote_pages = set(self.page_api.get_all_title())

        # 本地数据库
        local_posts = set([x.title for x in self.posts])
        local_pages = set([x.title for x in self.pages])

        # 即将删除的数据
        remote_only_post_title = remote_posts - local_posts
        remote_only_page_title = remote_pages - local_pages

        # 远程数据库有 本地无 多余 only pull delete show
        # 本地数据库有 远程无 新建
        show_data = {
            "mode": mode,
            "post": (
                ", ".join(filter(None, remote_only_post_title))
                if remote_only_post_title
                else ""
            ),
            "page": (
                ", ".join(filter(None, remote_only_page_title))
                if remote_only_page_title
                else ""
            ),
        }

        if not remote_only_post_title and not remote_only_page_title:
            log.success("CONFLICT", "无冲突已忽略")
            return

        if mode == "pull":
            posts = [self.post_api.get_post_by_title(x) for x in remote_only_post_title]
            pages = [self.page_api.get_page_by_title(x) for x in remote_only_page_title]
            self.pull(docs=docs, posts=posts, pages=pages)
            log.success("CONFLICT", "已拉取", **show_data)

        elif mode == "delete":
            [self.post_api.delete_post(x) for x in remote_only_post_title]
            [self.page_api.delete_page(x) for x in remote_only_page_title]
            log.success("CONFLICT", "已删除", **show_data)

        else:  # show mode
            log.success("CONFLICT", "仅展示额外的内容", **show_data)

    def showkey(self):
        log.info(apikey=self.api_key)

    def get_apikey(self, username, password):
        result = self.auth_api.login(username, password)
        log.info(**result)

    def new_apikey(self, api_key):
        result = self.auth_api.refresh_api_key(api_key)
        log.info(**result)

    def clean(self):
        resp = self.file_api.clean_extra_files()
        log.info("CLEAN", "完成", **resp)

    def push(self, docs):
        self.docs_to_data(docs)

        # 合并所有项目
        all_items = [(item, self.post_api, "post") for item in self.posts] + [
            (item, self.page_api, "page") for item in self.pages
        ]

        total = len(all_items)

        for current, (item, api, item_type) in enumerate(all_items, 1):
            item = self.upload_and_replace(item)
            item_dict = item.__dict__
            resp = api.create_or_update(item_dict)
            item_dict.update({"type": item_type, **resp})
            log.info(
                f"[{current}/{total}]", "PUSH", item_dict.get("title"), **item_dict
            )

    def pull(self, docs, posts=None, pages=None):
        if not posts:
            posts = self.post_api.get_posts(size=100000)
            posts = posts.get("posts", [])

        if not pages:
            pages = self.page_api.get_pages(size=100000)
            pages = pages.get("pages", [])

        # 合并所有项目
        all_items = [(item, "post") for item in posts] + [
            (item, "page") for item in pages
        ]
        total = len(all_items)

        for current, (item, item_type) in enumerate(all_items, 1):
            item = self.download_and_replace(item, docs)
            status = self.data_to_docs(item, docs)

            # 创建日志数据，排除不需要的字段
            log_data = {
                **item,
                "type": item_type,
                **status,
            }

            log.info(f"[{current}/{total}]", "PULL", item.get("title"), **log_data)

    def clear(self):
        # self.backup()

        remote_posts = set(self.post_api.get_all_title())
        remote_pages = set(self.page_api.get_all_title())

        [self.post_api.delete_post(x) for x in remote_posts]
        [self.page_api.delete_page(x) for x in remote_pages]

        log.info("CLEAR", "完成", post=len(remote_posts), page=len(remote_pages))
        self.clean()

    def backup(self, backup_path="backups"):
        """备份数据到指定目录"""
        result = self.root_api.backup_all(backup_path)
        log.info("BACKUP", "完成", **result)

    def restore(self, backup_path="backups"):
        """从备份目录恢复数据"""
        result = self.root_api.restore_all(backup_path)
        data_restore_result = result.get("data", {})
        static_restore_result = result.get("static", {})
        log.info("RESTORE", "完成", **data_restore_result)
        log.info("RESTORE", "完成", **static_restore_result)


class SimpleCLI:
    """简化的CLI处理类"""

    def __init__(
        self,
        base_url,
        api_key,
        docs_path="docs",
        backup_path="backups",
        conflict_mode="show",
    ):
        self.base_url = base_url
        self.api_key = api_key
        self.docs_path = docs_path
        self.backup_path = backup_path
        self.conflict_mode = conflict_mode

        self.parser = argparse.ArgumentParser(
            description="文档同步工具",
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog=self._get_epilog(),
        )
        self._setup_commands()
        self.log = log

    def _get_epilog(self):
        """返回使用示例说明"""
        return """
使用示例:
  # 推送本地文档到远程
  python main.py push

  # 从远程拉取文档到本地
  python main.py pull

  # 处理冲突（显示远程有但本地没有的文档）
  python main.py conflict

  # 拉取冲突文档（拉取远程有但本地没有的文档）
  python main.py conflict --mode pull

  # 删除冲突文档（删除远程有但本地没有的文档）
  python main.py conflict --mode delete

  # 清理远程多余的静态文件
  python main.py clean

  # 清空远程所有内容
  python main.py clear

  # 备份远程数据
  python main.py backup

  # 从备份恢复数据
  python main.py restore

  # 创建示例文档
  python main.py example

  # 创建模板文档
  python main.py template

  # 获取API密钥（通过用户名密码登录）
  python main.py get_apikey --username <用户名> --password <密码>

  # 刷新API密钥
  python main.py new_apikey
        """

    def _setup_commands(self):
        """设置命令和参数"""
        subparsers = self.parser.add_subparsers(dest="command")

        # push 命令
        subparsers.add_parser("push", help="推送本地文档到远程")

        # pull 命令
        subparsers.add_parser("pull", help="从远程拉取文档到本地")

        # conflict 命令
        conflict_parser = subparsers.add_parser("conflict", help="处理冲突文档")
        conflict_parser.add_argument(
            "--mode",
            choices=["show", "pull", "delete"],
            default=self.conflict_mode,
            help="处理模式: show(仅显示), pull(拉取), delete(删除)",
        )

        # get_apikey 命令
        get_apikey_parser = subparsers.add_parser(
            "getkey", help="通过用户名密码获取API密钥"
        )
        get_apikey_parser.add_argument("--username", required=True, help="用户名")
        get_apikey_parser.add_argument("--password", required=True, help="密码")

        # new_apikey 命令
        new_key = subparsers.add_parser("newkey", help="刷新API密钥")
        new_key.add_argument("--apikey", required=False, help="apikey")

        subparsers.add_parser("show", help="查看信息")
        # 备份命令
        subparsers.add_parser("backup", help="备份远程数据")

        # 恢复命令
        subparsers.add_parser("restore", help="从备份恢复数据")

        # 示例文档命令
        subparsers.add_parser("example", help="创建示例文档")

        # 模板文档命令
        subparsers.add_parser("template", help="创建模板文档")

        # 其他简单命令
        subparsers.add_parser("clean", help="清理远程多余的静态文件")
        subparsers.add_parser("clear", help="清空远程所有内容")

    def _print_logo(self):
        """打印Logo"""
        logo = rf"""
 _      __         __
| | /| / /__  ____/ /_____ ____
| |/ |/ / _ \/ __/  '_/ -_) __/
|__/|__/\___/_/ /_/\_\\__/_/     v1.0.0
"""
        print(f"\033[32m{logo}\033[0m")

    def run(self):
        """运行CLI"""
        args = self.parser.parse_args()

        # 显示Logo
        self._print_logo()

        if not args.command:
            self.log.debug("文档同步cli - 输入命令查看帮助")
            config = {
                "base_url": self.base_url,
                "api_key": self.api_key,
                "docs_path": self.docs_path,
                "backup_all": self.backup_path,
                "conflict_mode": self.conflict_mode,
            }
            self.log.info(**config)
            return 0

        try:
            worker = MainWorker(self.base_url, self.api_key)

            offline = ["example", "template"]

            # 简化的命令执行逻辑
            if args.command in ["push", "conflict"]:
                if not os.path.exists(self.docs_path):
                    self.log.error(f"文档路径不存在: {self.docs_path}")
                    return 1

                if args.command == "push":
                    worker.push(self.docs_path)
                else:  # conflict
                    worker.docs_to_data(self.docs_path)
                    conflict_mode = getattr(args, "mode", self.conflict_mode)
                    worker.conflict(mode=conflict_mode, docs=self.docs_path)

            elif args.command == "pull":
                if not os.path.exists(self.docs_path):
                    os.makedirs(self.docs_path)
                worker.pull(self.docs_path)

            elif args.command == "clean":
                worker.clean()

            elif args.command == "show":
                worker.showkey()
            elif args.command == "clear":
                if input("\033[93m确认清空远程所有内容? (y/N): ").lower() in [
                    "y",
                    "yes",
                ]:
                    worker.clear()
                else:
                    print("操作取消")

            elif args.command == "backup":
                if not os.path.exists(self.backup_path):
                    os.makedirs(self.backup_path)
                worker.backup(self.backup_path)

            elif args.command == "restore":
                if not os.path.exists(self.backup_path):
                    self.log.error(f"备份目录不存在: {self.backup_path}")
                    return 1
                worker.restore(self.backup_path)

            elif args.command == "example":
                worker.example_maker(self.docs_path)

            elif args.command == "template":
                worker.template_maker(self.docs_path)

            elif args.command == "getkey":
                # 通过用户名密码获取API密钥
                username = getattr(args, "username", None)
                password = getattr(args, "password", None)

                if not username or not password:
                    self.log.error("GET_APIKEY", "用户名和密码不能为空")
                    return 1

                api_key = worker.get_apikey(username, password)

            elif args.command == "newkey":
                api_key = getattr(args, "apikey", None)
                if not api_key:
                    api_key = self.api_key

                print(api_key)
                # 刷新API密钥
                new_key = worker.new_apikey(api_key)

        except Exception as e:
            self.log.error(f"执行错误: {e}")
            raise e
            # return 1

        return 0



def main(
    base_url, api_key, docs_path="docs", backup_path="backups", conflict_mode="show"
):
    return SimpleCLI(base_url, api_key, docs_path, backup_path, conflict_mode).run()


if __name__ == "__main__":
    # 记录开始时间
    start_time = time.time()

    # 硬编码所有配置参数
    config = {
        "base_url": "http://hon-ker.cn",
        "api_key": "",
        "docs_path": "/data/docs",  # 硬编码文档路径
        "backup_path": "/data/docs/.backups",  # 硬编码备份路径
        "conflict_mode": "show",  # 硬编码冲突处理模式
    }

    try:
        exit_code = main(
            base_url=config["base_url"],
            api_key=config["api_key"],
            docs_path=config["docs_path"],
            backup_path=config["backup_path"],
            conflict_mode=config["conflict_mode"],
        )
    except Exception as e:
        exit_code = 1
        raise e
    finally:
        # 计算运行时间
        end_time = time.time()
        elapsed_time = end_time - start_time

        # 格式化显示运行时间
        if elapsed_time < 60:
            time_str = f"{elapsed_time:.2f}秒"
        elif elapsed_time < 3600:
            minutes = int(elapsed_time // 60)
            seconds = elapsed_time % 60
            time_str = f"{minutes}分{seconds:.2f}秒"
        else:
            hours = int(elapsed_time // 3600)
            minutes = int((elapsed_time % 3600) // 60)
            seconds = elapsed_time % 60
            time_str = f"{hours}小时{minutes}分{seconds:.2f}秒"
        log.success(f"Run Time {time_str}")

    sys.exit(exit_code)
