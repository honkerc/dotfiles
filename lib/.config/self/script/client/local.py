import re
import yaml
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass, field, asdict
import urllib.parse

class SimpleLog:

    def __init__(self, detail_color="\033[90m"):
        self.detail_color = detail_color

    def info(self, *args, **kwargs):
        self._log("\033[94m[-]\033[0m", *args, **kwargs)

    def success(self, *args, **kwargs):
        self._log("\033[92m[+]\033[0m", *args, **kwargs)

    def debug(self, *args, **kwargs):
        self._log("\033[97m[-]\033[0m", *args, **kwargs)

    def error(self, *args, **kwargs):
        self._log("\033[91m[!]", *args, **kwargs)

    def warning(self, *args, **kwargs):
        self._log("\033[93m[?]\033[0m", *args, **kwargs)

    def _log(self, symbol, *args, **kwargs):
        if args:
            print(f"{symbol}", *args)

        if kwargs:
            ignore_list = kwargs.get("ignore_list",["content","excerpt","description","attach","files"])
            show_ignore = kwargs.get("show_ignore",False)
            max_key_length = max(len(str(key)) for key in kwargs.keys())

            for key, value in kwargs.items():
                if not show_ignore and key in ignore_list:
                    continue
                if isinstance(value, (dict, list, tuple, set)):
                    formatted_value = str(value)
                elif isinstance(value, str):
                    formatted_value = f"'{value}'"
                else:
                    formatted_value = str(value)

                terminal_context = f"{self.detail_color}│ {str(key):>{max_key_length}} : {formatted_value}\033[0m"
                print(terminal_context)

log = SimpleLog()

@dataclass
class Post:
    title: str
    content: str
    tag: str = ""
    category: str = ""
    excerpt: str = ""
    cover: str = ""
    is_top: bool = False
    is_locked: bool = False
    attach: List[Dict[str, str]] = field(default_factory=list)
    file_path: str = ""

@dataclass
class Page:
    title: str
    content: str
    description: str = ""
    icon: str = ""
    is_active: bool = True
    order: int = 10
    attach: List[Dict[str, str]] = field(default_factory=list)
    file_path: str = ""

class DocsScanner:
    def __init__(self, docs_root: str = "docs", ignore_list: List = None):
        self.docs_root = Path(docs_root)
        self.supported_extensions = {'.md', '.markdown',".txt"}

        if ignore_list is None:
            self.ignore_list = ["文章模板.md", "页面模板.md","草稿"]
        else:
            self.ignore_list = ignore_list

    def _should_ignore_file(self, file_path: Path) -> bool:
        if file_path.name in self.ignore_list:
            return True

        for ignore_pattern in self.ignore_list:
            if ignore_pattern in str(file_path):
                return True

        return False

    def parse_frontmatter(self, content: str) -> Tuple[Dict[str, Any], str]:
        metadata = {}
        pure_content = content

        frontmatter_pattern = r'^---\s*\n(.*?)\n---\s*\n(.*)$'
        match = re.match(frontmatter_pattern, content, re.DOTALL)

        if match:
            try:
                frontmatter_content = match.group(1)
                pure_content = match.group(2)
                metadata = yaml.safe_load(frontmatter_content) or {}
            except (yaml.YAMLError, Exception):
                pass

        return metadata, pure_content

    def extract_cover_from_content(self, content: str) -> str:
        img_pattern = r'!\[.*?\]\((.*?)\)'
        matches = re.findall(img_pattern, content)
        if matches:
            return matches[0].replace("file://", "")

        html_img_pattern = r'<img.*?src="(.*?)".*?>'
        html_matches = re.findall(html_img_pattern, content)
        return html_matches[0] if html_matches else ""

    def generate_excerpt(self, content: str, length: int = 150) -> str:
        clean_content = re.sub(r'[#*`\[\]!]', '', content)
        clean_content = re.sub(r'\s+', ' ', clean_content).strip()

        if len(clean_content) <= length:
            return clean_content

        return clean_content[:length] + "..."

    def get_category_and_tag_from_path(self, file_path: Path) -> Tuple[str, str]:
        try:
            relative_path = file_path.relative_to(self.docs_root)
            parts = relative_path.parts

            if len(parts) == 1:
                return "", ""

            category = parts[0]
            tag = parts[1] if len(parts) > 2 else ""

            return category, tag
        except ValueError:
            return "", ""

    def extract_title(self, metadata: Dict[str, Any], content: str, file_path: Path) -> str:
        if 'title' in metadata and metadata['title']:
            return metadata['title']

        h1_pattern = r'^#\s+(.+)$'
        match = re.search(h1_pattern, content, re.MULTILINE)
        if match:
            return match.group(1).strip()

        return Path(file_path.name).stem

    def _is_external_url(self, url: str) -> bool:
        external_prefixes = ('http://', 'https://', '//', 'ftp://', 'mailto:', 'tel:')
        return url.startswith(external_prefixes)

    def _clean_url(self, url: str) -> str:
        try:
            url = urllib.parse.unquote(url)
        except:
            pass

        parts = urllib.parse.urlparse(url)
        clean_path = parts.path

        return clean_path

    def _resolve_file_path(self, file_path_str: str, parent_dir: Path) -> Path:
        clean_path = self._clean_url(file_path_str)

        if clean_path.startswith('/'):
            return Path(clean_path)

        return (parent_dir / clean_path).resolve()

    def _extract_all_attachments(self, content: str, parent_dir: Path) -> List[Dict[str, str]]:
        """统一提取所有类型的附件"""
        attachments = []
        found_paths = set()

        # 1. 提取Markdown图片: ![alt](path) 或 ![alt](path "title")
        img_pattern = r'!\[.*?\]\(\s*([^)\s]+)(?:\s+[^)]*)?\s*\)'
        img_matches = re.findall(img_pattern, content)

        for file_path_str in img_matches:
            file_path_str = file_path_str.strip('"\'')
            if self._is_external_url(file_path_str) or file_path_str in found_paths:
                continue

            abs_path = self._resolve_file_path(file_path_str, parent_dir)
            if abs_path.exists() and abs_path.is_file():
                attachments.append({
                    "origin": file_path_str,
                    "absolute": str(abs_path),
                    "filename": abs_path.name,
                    "type": "image"
                })
                found_paths.add(file_path_str)

        # 2. 提取HTML图片: <img src="path">
        html_img_pattern = r'<img[^>]*src=["\']([^"\']+)["\'][^>]*>'
        html_matches = re.findall(html_img_pattern, content, re.IGNORECASE)

        for file_path_str in html_matches:
            if self._is_external_url(file_path_str) or file_path_str in found_paths:
                continue

            abs_path = self._resolve_file_path(file_path_str, parent_dir)
            if abs_path.exists() and abs_path.is_file():
                attachments.append({
                    "origin": file_path_str,
                    "absolute": str(abs_path),
                    "filename": abs_path.name,
                    "type": "image"
                })
                found_paths.add(file_path_str)

        # 3. 提取Markdown链接中的文件: [text](path)
        link_pattern = r'\[.*?\]\(\s*([^)\s]+)(?:\s+[^)]*)?\s*\)'
        link_matches = re.findall(link_pattern, content)

        for file_path_str in link_matches:
            file_path_str = file_path_str.strip('"\'')
            if (self._is_external_url(file_path_str) or
                file_path_str in found_paths):
                continue

            abs_path = self._resolve_file_path(file_path_str, parent_dir)
            if abs_path.exists() and abs_path.is_file():
                attachments.append({
                    "origin": file_path_str,
                    "absolute": str(abs_path),
                    "filename": abs_path.name,
                    "type": "file"
                })
                found_paths.add(file_path_str)

        # 4. 提取直接文件路径（更宽松的匹配）
        # 匹配包含常见文件扩展名的路径
        file_extensions = r'\.(jpg|jpeg|png|gif|webp|bmp|pdf|doc|docx|txt|zip|rar|mp4|avi|mov|mp3|wav|ogg|svg|ico)'
        direct_pattern = rf'[\w\/\.\-~]+{file_extensions}'
        direct_matches = re.findall(direct_pattern, content, re.IGNORECASE)

        for file_path_str in direct_matches:
            if (self._is_external_url(file_path_str) or
                file_path_str in found_paths or
                file_path_str.startswith('http')):
                continue

            abs_path = self._resolve_file_path(file_path_str, parent_dir)
            if abs_path.exists() and abs_path.is_file():
                attachments.append({
                    "origin": file_path_str,
                    "absolute": str(abs_path),
                    "filename": abs_path.name,
                    "type": "direct"
                })
                found_paths.add(file_path_str)

        return attachments

    def find_attachments(self, file_path: Path) -> List[Dict[str, str]]:
        """查找文章中的所有附件"""
        attachments = []

        try:
            content = file_path.read_text(encoding='utf-8')
            parent_dir = file_path.parent

            attachments = self._extract_all_attachments(content, parent_dir)

        except Exception as e:
            pass

        return attachments

    def get_tag_from_metadata(self, metadata: Dict[str, Any], tag_from_path: str) -> str:
        tag_value = metadata.get('tag')
        if tag_value:
            if isinstance(tag_value, list) and tag_value:
                return str(tag_value[0])
            return str(tag_value)

        tags_value = metadata.get('tags')
        if tags_value:
            if isinstance(tags_value, list) and tags_value:
                return str(tags_value[0])
            elif tags_value:
                return str(tags_value)

        return tag_from_path

    def scan_post_file(self, file_path: Path) -> Optional[Post]:
        if file_path.suffix.lower() not in self.supported_extensions:
            return None

        try:
            content = file_path.read_text(encoding='utf-8')
            metadata, pure_content = self.parse_frontmatter(content)
            category, tag_from_path = self.get_category_and_tag_from_path(file_path)

            if not category:
                return None

            title = self.extract_title(metadata, pure_content, file_path)
            tag = self.get_tag_from_metadata(metadata, tag_from_path)
            excerpt = metadata.get('excerpt', self.generate_excerpt(pure_content))

            cover_from_metadata = metadata.get('cover')
            cover = cover_from_metadata if cover_from_metadata else self.extract_cover_from_content(pure_content)

            is_top = metadata.get('is_top', False)
            is_locked = metadata.get('is_locked', False)
            attachments = self.find_attachments(file_path)

            return Post(
                title=title,
                content=pure_content,
                tag=tag,
                category=category,
                excerpt=excerpt,
                cover=cover,
                is_top=is_top,
                is_locked=is_locked,
                attach=attachments,
                file_path=str(file_path)
            )

        except Exception as e:
            return None

    def scan_page_file(self, file_path: Path) -> Optional[Page]:
        if file_path.suffix.lower() not in self.supported_extensions:
            return None

        try:
            content = file_path.read_text(encoding='utf-8')
            metadata, pure_content = self.parse_frontmatter(content)

            name = metadata.get('name', Path(file_path.name).stem)
            title = self.extract_title(metadata, pure_content, file_path)
            description = metadata.get('description', self.generate_excerpt(pure_content))
            icon = metadata.get('icon', "")
            is_active = metadata.get('is_active', True)
            order = metadata.get('order', 10)

            attachments = self.find_attachments(file_path)

            return Page(
                title=title,
                content=pure_content,
                description=description,
                icon=icon,
                is_active=is_active,
                order=order,
                attach=attachments,
                file_path=str(file_path)
            )

        except Exception as e:
            return None

    def scan_directory(self) -> Tuple[List[Post], List[Page]]:
        posts = []
        pages = []

        if not self.docs_root.exists():
            return posts, pages

        for file_path in self.docs_root.rglob("*"):
            if self._should_ignore_file(file_path):
                continue

            if file_path.is_file() and file_path.suffix.lower() in self.supported_extensions:
                try:
                    relative_path = file_path.relative_to(self.docs_root)
                    if len(relative_path.parts) == 1:
                        page = self.scan_page_file(file_path)
                        if page:
                            pages.append(page)
                    else:
                        post = self.scan_post_file(file_path)
                        if post:
                            posts.append(post)
                except ValueError:
                    continue

        return posts, pages

    def get_all_posts(self) -> List[Post]:
        posts, _ = self.scan_directory()
        return posts

    def get_all_pages(self) -> List[Page]:
        _, pages = self.scan_directory()
        return pages

    def get_posts_summary(self, posts: List[Post]) -> List[Dict[str, Any]]:
        return [
            {
                "title": post.title,
                "category": post.category,
                "tag": post.tag,
                "file_path": post.file_path,
                "attachment_count": len(post.attach)
            }
            for post in posts
        ]

    def get_pages_summary(self, pages: List[Page]) -> List[Dict[str, Any]]:
        return [
            {
                "title": page.title,
                "description": page.description,
                "file_path": page.file_path,
                "attachment_count": len(page.attach)
            }
            for page in pages
        ]

class DocsMaker:

    def __init__(self, docs_dir):
        self.docs_dir = Path(docs_dir)
        self.docs_dir.mkdir(parents=True, exist_ok=True)

    def example_dir(self):
        example_list = ["笔记", "测试"]
        for x in example_list:
            path = self.docs_dir / x
            path.mkdir(exist_ok=True)

    def example_data(self):
        return [
            ("page", "关于.md", "## 关于博客\n\n这是我的个人博客，分享技术文章和生活感悟。\n\n### 博客特点\n\n- 技术文章分享\n- 学习笔记记录\n- 项目经验总结\n\n欢迎交流讨论！"),
            ("page", "友链.md", "# 友情链接\n\n## 我的博客信息\n\n**博客名称**：红客路上  \n**博客网址**：http://hon-ker.cn  \n**博客描述**：荣耀之前是长夜的等待  \n**头像链接**：http://hon-ker.cn/static/avatar.jpg  \n**联系邮箱**：clay@hon-ker.cn\n\n---\n\n## 优秀博客推荐\n\n### 技术类博客\n\n-  [TechStack](https://techstack.example.com)  - 专注于全栈开发技术分享\n- [算法之美](https://algo.example.com) - 算法学习与竞赛经验\n- [DevOps实践](https://devops.example.com) - DevOps工具链与最佳实践\n\n### 设计类博客\n\n- [UI设计派](https://ui.example.com) - UI/UX设计理念与案例\n- [创意视觉](https://creative.example.com) - 平面设计与视觉艺术\n\n### 生活类博客\n\n- [旅行者的笔记](https://travel.example.com) - 环球旅行见闻与攻略\n- [阅读时光](https://reading.example.com) - 读书笔记与文学评论\n\n---\n\n## 友链交换说明\n\n### 基本要求\n\n1. **内容质量**：网站内容原创度高，有价值且定期更新\n2. **主题相关**：优先考虑技术、编程、设计、创业等相关主题\n3. **网站稳定**：网站可正常访问，无大量广告或弹窗\n4. **合法合规**：内容符合法律法规，不涉及敏感话题\n\n### 申请方式\n\n请按照以下格式在您的网站添加本站链接后，通过邮件联系我：\n\n**站点名称**：Clay的技术博客  \n**站点地址**：https://blog.clay.com  \n**站点描述**：分享编程技术、开发经验和生活思考\n\n然后发送邮件至 contact@clay.com，附上您的：\n- 网站名称\n- 网站地址\n- 网站描述\n- logo/头像链接（可选）\n\n### 注意事项\n\n- 我会在1-3个工作日内审核并添加符合要求的友链\n- 如链接失效或内容不符合要求，我保留移除链接的权利\n- 欢迎技术交流与合作，共同进步！\n\n---\n\n*感谢所有支持本站的朋友，让我们一起创造更有价值的互联网内容！*"),
            ("post", "测试/关于cli的其相关说明.md", "# CLI 工具使用说明\n\n## 功能概述\n\n这是一个用于博客管理的命令行工具，支持文章的发布、更新和同步。\n\n### 主要命令\n\n```bash\npython main.py push      # 推送本地文章\npython main.py pull      # 拉取远程文章\npython main.py backup    # 备份数据\n```\n\n### 配置说明\n\n工具使用 YAML 配置文件，支持自定义服务器地址和 API 密钥。"),
            ("post", "笔记/笔记的名字可以随意.md", "# 任务清单\n\n## 待办事项\n- [ ] 编写项目文档\n- [ ] 修复 Bug #123\n- [ ] 代码审查\n- [ ] 学习新技术\n- [ ] 整理工作笔记\n\n## 进行中\n- [x] 设计数据库架构\n- [ ] 开发用户模块\n- [ ] 编写测试用例\n\n## 已完成\n- [x] 项目需求分析\n- [x] 技术选型\n- [x] 环境搭建\n\n---\n**进度**：3/8 已完成 (37.5%)"),
        ]

    def meta(self):
        return {
            "post": {
                'title': '',
                'category': '',
                'tag': '',
                'excerpt': '随便写点什么当摘要...',
                'cover': '',
                'is_top': False,
                'is_locked': False
            },
            "page": {
                'title': '',
                'description': '',
                'icon': 'czs-block-l',
                'is_active': True,
                'order': 100
            }
        }

    def format_meta(self, meta: Dict) -> str:
        yaml_content = yaml.dump(
            meta,
            default_flow_style=False,
            allow_unicode=True,
            sort_keys=False,
            indent=2
        )

        front_matter = f"---\n{yaml_content}---\n"
        return front_matter

    def write_file(self, filename, content):
        try:
            with open(filename, "w", encoding="utf-8") as file:
                file.write(content)
        except Exception as e:
            raise e

    def example_maker(self):
        self.example_dir()
        meta = self.meta()

        for file_type, filename, content in self.example_data():
            file_path = self.docs_dir / filename
            title = Path(filename).stem

            file_meta = meta[file_type].copy()
            file_meta['title'] = title

            meta_data = self.format_meta(file_meta)
            full_content = meta_data + "\n" + content

            file_path.parent.mkdir(parents=True, exist_ok=True)
            self.write_file(file_path, full_content)

    def template_maker(self):
        meta = self.meta()
        template = [("post","文章模板.md"),("page","页面模板.md")]
        for type,file in template:
            file_path =  self.docs_dir / file
            file_path.parent.mkdir(parents=True, exist_ok=True)
            file_meta = meta[type].copy()

            meta_data = self.format_meta(file_meta)
            self.write_file(file_path, meta_data+"\n")

if __name__ == "__main__":
    template = DocsMaker("docs")
    template.template_maker()
