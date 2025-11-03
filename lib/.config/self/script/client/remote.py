from typing import List, Dict, Any, Optional
from datetime import datetime
from pathlib import Path
from local import Post,log
import requests
import urllib
import json
import os

def compare_dicts(dict1, dict2, normalize_empty=True, ignore_keys=None):
    """
    详细版比较，包含具体的值差异
    """
    if ignore_keys is None:
        ignore_keys = ["attach", "file_path"]

    shorter, longer = (dict1, dict2) if len(dict1) <= len(dict2) else (dict2, dict1)

    diff_key = []

    # 检查缺失的键
    for key in shorter.keys():
        if key in ignore_keys:
            continue
        if key not in longer:
            diff_key.append(key)

    # 检查值不匹配（包含具体值）
    for key, short_value in shorter.items():
        if key in ignore_keys:
            continue
        if key not in longer:
            continue

        long_value = longer[key]

        if normalize_empty:
            short_norm = None if short_value == "" else short_value
            long_norm = None if long_value == "" else long_value
        else:
            short_norm = short_value
            long_norm = long_value

        if short_norm != long_norm:
            diff_key.append(key)

    is_match = len(diff_key) == 0
    return is_match, {"diff":", ".join(diff_key)}

class BaseRemoteAPI:
    """远程API基类，集中处理请求方法和认证"""

    def __init__(self, base_url: str, api_key: str):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.headers = {
            "Content-Type": "application/json",
            "X-API-Key": api_key
        }

    def _request(self, method: str, endpoint: str, **kwargs) -> requests.Response:
        """统一请求方法"""
        url = f"{self.base_url}{endpoint}"

        # 添加 API key 到查询参数
        params = kwargs.get('params', {})
        params['api_key'] = self.api_key
        kwargs['params'] = params

        # 添加 headers
        if 'headers' not in kwargs:
            kwargs['headers'] = self.headers

        try:
            response = requests.request(method, url, **kwargs)
            return response
        except requests.exceptions.RequestException as e:
            print(f"请求失败: {e}")
            raise



class AuthAPI(BaseRemoteAPI):
    """认证相关的远程API客户端"""

    def __init__(self, base_url, api_key = ""):
        super().__init__(base_url, api_key)

    def login(self, username: str, password: str) -> Dict[str, Any]:
        """
        用户登录，获取 API Key

        Args:
            username: 用户名
            password: 密码

        Returns:
            登录响应，包含 API Key 和用户信息
        """
        endpoint = "/api/meta/login"
        login_data = {
            "name": username,
            "password": password
        }

        # 登录请求不需要 API Key
        headers = {k: v for k, v in self.headers.items() if k != 'X-API-Key'}
        response = self._request("POST", endpoint, json=login_data, headers=headers)

        if response.status_code == 200:
            result = response.json()
            # 如果登录成功，更新实例的 API Key
            if result.get('success') and result.get('api_key'):
                self.api_key = result['api_key']
                self.headers["X-API-Key"] = self.api_key
            return result
        else:
            raise Exception(f"登录失败: {response.status_code} - {response.text}")

    def refresh_api_key(self,api_key) -> Dict[str, Any]:
        """
        刷新 API Key

        Returns:
            包含新 API Key 的响应

        Raises:
            Exception: 如果没有设置 API Key 或刷新失败
        """
        if not self.api_key:
            raise Exception("需要先登录获取 API Key")

        endpoint = f"/api/meta/refresh-api-key?api_key={api_key}"
        response = self._request("POST", endpoint)

        if response.status_code == 200:
            result = response.json()
            # 更新实例的 API Key
            if result.get('success') and result.get('api_key'):
                self.api_key = result['api_key']
                self.headers["X-API-Key"] = self.api_key
            return result
        else:
            raise Exception(f"刷新 API Key 失败: {response.status_code} - {response.text}")

    def verify_api_key(self) -> Dict[str, Any]:
        """
        验证当前 API Key 是否有效

        Returns:
            验证结果

        Raises:
            Exception: 如果没有设置 API Key 或验证失败
        """
        if not self.api_key:
            raise Exception("需要先登录获取 API Key")

        endpoint = "/api/meta/verify-api-key"  # 根据您的实际端点调整
        response = self._request("GET", endpoint)

        if response.status_code == 200:
            return True
        else:
            return response
            raise Exception(f"验证 API Key 失败: {response.status_code} - {response.text}")

    def get_meta_info(self) -> Dict[str, Any]:
        """
        获取网站元数据信息

        Returns:
            网站元数据
        """
        endpoint = "/api/meta"
        response = self._request("GET", endpoint)

        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"获取元数据失败: {response.status_code} - {response.text}")


class RemotePostAPI(BaseRemoteAPI):
    """远程 Post API 客户端"""

    def create_post(self, post_data: Dict[str, Any]) -> Dict[str, Any]:
        """创建文章"""
        endpoint = "/api/admin/posts/"
        response = self._request("POST", endpoint, json=post_data)

        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"创建文章失败: {response.status_code} - {response.text}")

    def get_posts(
        self,
        page: int = 1,
        size: int = 10,
        category: Optional[str] = None,
        is_locked: Optional[bool] = None,
        is_top: Optional[bool] = None
    ) -> Dict[str, Any]:
        """获取文章列表"""
        endpoint = "/api/posts/"
        params = {
            "page": page,
            "size": size
        }

        if category:
            params["category"] = category
        if is_locked is not None:
            params["is_locked"] = str(is_locked).lower()
        if is_top is not None:
            params["is_top"] = str(is_top).lower()

        response = self._request("GET", endpoint, params=params)

        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"获取文章列表失败: {response.status_code} - {response.text}")

    def get_all_title(self) -> Dict[str, Any]:
        """获取文章详情"""
        endpoint = f"/api/posts/all"
        response = self._request("GET", endpoint)
        return response.json()

    def get_post_by_title(self, post_title: str) -> Dict[str, Any]:
        """获取文章详情"""
        endpoint = f"/api/posts/title/{post_title}"
        response = self._request("GET", endpoint)

        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"获取文章详情失败: {response.status_code} - {response.text}")

    def update_post(self, post_title: str, post_data: Dict[str, Any]) -> Dict[str, Any]:
        """更新文章"""
        endpoint = f"/api/admin/posts/{post_title}"
        response = self._request("PUT", endpoint, json=post_data)

        if response.status_code == 200:
            return response.json()
        elif response.status_code == 404:
            raise Exception(f"文章不存在: {post_title}")
        elif response.status_code == 409:
            raise Exception(f"文章标题已存在: {post_data.get('title')}")
        else:
            raise Exception(f"更新文章失败: {response.status_code} - {response.text}")

    def delete_post(self, post_title: str) -> bool:
        """删除文章"""
        endpoint = f"/api/admin/posts/{post_title}"
        response = self._request("DELETE", endpoint)

        if response.status_code == 200:
            return True
        elif response.status_code == 404:
            raise Exception(f"文章不存在: {post_title}")
        else:
            raise Exception(f"删除文章失败: {response.status_code} - {response.text}")

    def toggle_top(self, post_title: str, is_top: bool) -> Dict[str, Any]:
        """置顶/取消置顶文章"""
        endpoint = f"/api/admin/posts/{post_title}/top"
        params = {"is_top": str(is_top).lower()}
        response = self._request("PATCH", endpoint, params=params)

        if response.status_code == 200:
            return response.json()
        elif response.status_code == 404:
            raise Exception(f"文章不存在: {post_title}")
        else:
            raise Exception(f"置顶操作失败: {response.status_code} - {response.text}")

    def toggle_lock(self, post_title: str, is_locked: bool) -> Dict[str, Any]:
        """锁定/解锁文章"""
        endpoint = f"/api/admin/posts/{post_title}/lock"
        params = {"is_locked": str(is_locked).lower()}
        response = self._request("PATCH", endpoint, params=params)

        if response.status_code == 200:
            return response.json()
        elif response.status_code == 404:
            raise Exception(f"文章不存在: {post_title}")
        else:
            raise Exception(f"锁定操作失败: {response.status_code} - {response.text}")

    def create_or_update(self, post_data: Dict[str, Any]):
        try:
            post = self.get_post_by_title(post_data.get("title"))
            is_same,diffs =  compare_dicts(post,post_data)

            if is_same:
                return {"Ignore":"success"}
            else:
                resp = self.update_post(post_data.get('title'),post_data)

                return {**diffs,"update":"success"}


        except Exception as e:
            resp = self.create_post(post_data)
            return  {"create":"success"}

    def batch_create_posts(self, posts: List[Post]) -> List[Dict[str, Any]]:
        """批量创建文章"""
        results = []

        for i, post in enumerate(posts, 1):
            try:
                print(f"创建文章 [{i}/{len(posts)}]: {post.title}")

                # 转换 Post 对象为 API 请求数据
                post_data = {
                    "title": post.title,
                    "content": post.content,
                    "tag": post.tag,
                    "category": post.category,
                    "excerpt": post.excerpt,
                    "cover": post.cover,
                    "is_top": post.is_top,
                    "is_locked": post.is_locked
                }

                # 创建文章
                result = self.create_post(post_data)
                results.append({
                    "success": True,
                    "post": result,
                    "original_post": post
                })
                print(f"✅ 创建成功: {post.title}")

            except Exception as e:
                results.append({
                    "success": False,
                    "error": str(e),
                    "original_post": post
                })
                print(f"❌ 创建失败: {post.title} - {e}")

        return results

    def test_connection(self) -> bool:
        """测试连接"""
        try:
            # 尝试获取第一页文章列表
            result = self.get_posts(page=1, size=1)
            return True
        except Exception as e:
            print(f"连接测试失败: {e}")
            return False


class RemotePageAPI(BaseRemoteAPI):
    """远程 Page API 客户端"""

    def create_page(self, page_data: Dict[str, Any]) -> Dict[str, Any]:
        """创建页面"""
        endpoint = "/api/admin/pages/"
        response = self._request("POST", endpoint, json=page_data)

        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"创建页面失败: {response.status_code} - {response.text}")

    def get_all_title(self) -> Dict[str, Any]:
        """获取文章详情"""
        endpoint = f"/api/pages/all"
        response = self._request("GET", endpoint)
        return response.json()

    def get_pages(
        self,
        page: int = 1,
        size: int = 10,
        is_active: Optional[bool] = None
    ) -> Dict[str, Any]:
        """获取页面列表"""
        endpoint = "/api/admin/pages/"
        params = {
            "page": page,
            "size": size
        }

        if is_active is not None:
            params["is_active"] = str(is_active).lower()

        response = self._request("GET", endpoint, params=params)

        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"获取页面列表失败: {response.status_code} - {response.text}")

    def get_page_by_title(self, title:str) -> Dict[str, Any]:
        """根据ID获取页面详情"""
        endpoint = f"/api/pages/{title}"
        response = self._request("GET", endpoint)
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"获取页面详情失败: {response.status_code} - {response.text}")

    def update_page(self, page_data: Dict[str, Any]) -> Dict[str, Any]:
        """更新页面（通过名称）"""
        endpoint = "/api/admin/pages/"
        response = self._request("PUT", endpoint, json=page_data)

        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"更新页面失败: {response.status_code} - {response.text}")

    def delete_page(self, post_title:str) -> bool:
        """根据ID删除页面"""
        endpoint = f"/api/admin/pages/{post_title}"
        response = self._request("DELETE", endpoint)

        if response.status_code == 200:
            return True
        elif response.status_code == 404:
            raise Exception(f"页面不存在: {post_title}")
        else:
            raise Exception(f"删除页面失败: {response.status_code} - {response.text}")

    def create_or_update(self, page_data: Dict[str, Any]):

        title = page_data.get("title")
        try:
            page = self.get_page_by_title(title)
            is_same,diffs =  compare_dicts(page,page_data)
            if is_same:
                return {"Ignore":"success"}
            else:
                resp = self.update_page(page_data)
                return {**diffs,"update":"success"}

        except Exception as e:
            resp = self.create_page(page_data)
            return  {"create":"success"}


    def toggle_page_status(self, post_title:str) -> Dict[str, Any]:
        """切换页面状态（启用/禁用）"""
        endpoint = f"/api/admin/pages/{post_title}/toggle"
        response = self._request("PATCH", endpoint)

        if response.status_code == 200:
            return response.json()
        elif response.status_code == 404:
            raise Exception(f"页面不存在: {post_title}")
        else:
            raise Exception(f"切换页面状态失败: {response.status_code} - {response.text}")

    def batch_create_pages(self, pages: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """批量创建页面"""
        results = []

        for i, page_data in enumerate(pages, 1):
            try:
                print(f"创建页面 [{i}/{len(pages)}]: {page_data.get('name')}")

                result = self.create_page(page_data)
                results.append({
                    "success": True,
                    "page": result,
                    "original_data": page_data
                })
                print(f"✅ 创建成功: {page_data.get('name')}")

            except Exception as e:
                results.append({
                    "success": False,
                    "error": str(e),
                    "original_data": page_data
                })
                print(f"❌ 创建失败: {page_data.get('name')} - {e}")

        return results

    def test_connection(self) -> bool:
        """测试连接"""
        try:
            # 尝试获取第一页页面列表
            result = self.get_pages(page=1, size=1)
            return True
        except Exception as e:
            print(f"连接测试失败: {e}")
            return False


class RemoteFileAPI(BaseRemoteAPI):
    """远程文件上传 API 客户端"""

    def __init__(self, base_url: str, api_key: str):
        super().__init__(base_url, api_key)
        # 文件上传不需要JSON Content-Type
        self.headers = {"X-API-Key": api_key}

    def upload_single(self, file_path: str, compress: bool = True) -> Dict[str, Any]:
        """单文件上传"""
        endpoint = "/api/file/single"

        if not os.path.exists(file_path):
            raise Exception(f"文件不存在: {file_path}")

        try:
            with open(file_path, 'rb') as file:
                files = {'file': (os.path.basename(file_path), file)}
                response = self._request("POST", endpoint, files=files)

            if response.status_code == 200:
                return response.json()
            else:
                raise Exception(f"文件上传失败: {response.status_code} - {response.text}")

        except Exception as e:
            raise Exception(f"上传文件时出错: {e}")

    def upload_multiple(self, file_paths: List[str], compress: bool = True) -> Dict[str, Any]:
        """多文件上传（最多20个文件）"""
        endpoint = "/api/file/multi"

        if not file_paths:
            raise Exception("没有提供文件路径")

        if len(file_paths) > 20:
            raise Exception("一次最多上传20个文件")

        files = []
        for file_path in file_paths:
            if not os.path.exists(file_path):
                print(f"文件不存在，跳过: {file_path}")
                continue

            files.append(('files', (os.path.basename(file_path), open(file_path, 'rb'))))

        if not files:
            raise Exception("没有有效的文件可上传")

        try:
            response = self._request("POST", endpoint, files=files)

            # 关闭所有文件句柄
            for file_field in files:
                file_field[1][1].close()

            if response.status_code == 200:
                return response.json()
            else:
                raise Exception(f"多文件上传失败: {response.status_code} - {response.text}")

        except Exception as e:
            # 确保文件句柄被关闭
            for file_field in files:
                try:
                    file_field[1][1].close()
                except:
                    pass
            raise Exception(f"多文件上传时出错: {e}")

    def upload_directory(self, directory_path: str, file_extensions: Optional[List[str]] = None, batch_size: int = 10) -> List[Dict[str, Any]]:
        """上传目录中的所有文件"""
        if not os.path.exists(directory_path) or not os.path.isdir(directory_path):
            raise Exception(f"目录不存在: {directory_path}")

        # 获取目录中的所有文件
        all_files = []
        for file_path in Path(directory_path).rglob('*'):
            if file_path.is_file():
                if file_extensions:
                    if file_path.suffix.lower() in [ext.lower() for ext in file_extensions]:
                        all_files.append(str(file_path))
                else:
                    all_files.append(str(file_path))

        if not all_files:
            print(f"目录中没有找到文件: {directory_path}")
            return []

        print(f"找到 {len(all_files)} 个文件准备上传")

        results = []

        # 分批上传
        for i in range(0, len(all_files), batch_size):
            batch = all_files[i:i + batch_size]
            print(f"上传批次 {i//batch_size + 1}/{(len(all_files) + batch_size - 1)//batch_size}: {len(batch)} 个文件")

            try:
                batch_result = self.upload_multiple(batch)
                results.append(batch_result)

                # 打印批次结果
                success_count = len([r for r in batch_result.get('results', []) if r.get('success')])
                print(f"  批次结果: 成功 {success_count}/{len(batch)}")

            except Exception as e:
                print(f"  批次上传失败: {e}")
                results.append({
                    "success": False,
                    "error": str(e),
                    "batch_files": batch
                })

        return results

    def test_connection(self) -> bool:
        """测试连接"""
        try:
            # 创建一个小的测试文件来测试上传
            test_file_path = "test_connection.txt"
            with open(test_file_path, 'w') as f:
                f.write("Connection test file")

            try:
                result = self.upload_single(test_file_path)
                # 如果上传成功，删除测试文件
                os.remove(test_file_path)
                return True
            except:
                # 如果上传失败，也删除测试文件
                if os.path.exists(test_file_path):
                    os.remove(test_file_path)
                return False

        except Exception:
            return False

    def get_upload_stats(self, upload_results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """获取上传统计信息"""
        total_files = 0
        successful_uploads = 0
        total_size = 0
        compressed_files = 0

        for result in upload_results:
            if isinstance(result, dict) and result.get('success'):
                if 'results' in result:
                    # 多文件上传结果
                    for file_result in result.get('results', []):
                        total_files += 1
                        if file_result.get('success'):
                            successful_uploads += 1
                            if file_result.get('compressed'):
                                compressed_files += 1
                else:
                    # 单文件上传结果
                    total_files += 1
                    successful_uploads += 1
                    if result.get('compressed'):
                        compressed_files += 1

        return {
            "total_files": total_files,
            "successful_uploads": successful_uploads,
            "failed_uploads": total_files - successful_uploads,
            "compressed_files": compressed_files,
            "success_rate": round(successful_uploads / total_files * 100, 2) if total_files > 0 else 0
        }

    def download_single(self, remote_file_path: str, output_path: str) -> bool:
        """
        下载单个文件

        Args:
            remote_file_path: 远程文件路径，例如 "uploads/sun.jpg"
            output_path: 本地保存路径

        Returns:
            bool: 下载是否成功
        """
        endpoint = f"/api/file/{urllib.parse.quote(remote_file_path)}"

        try:
            # 确保输出目录存在
            output_dir = Path(output_path).parent
            output_dir.mkdir(parents=True, exist_ok=True)

            # 发送下载请求
            response = self._request("GET", endpoint, stream=True)

            if response.status_code == 200:
                # 保存文件
                with open(output_path, 'wb') as f:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                return True
            else:
                return response
        except Exception as e:
            raise e

    def clean_extra_files(self):
        response = self._request("DELETE", "/api/file/clean", stream=True)
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception("文件清理失败")


class RemoteRootAPI(BaseRemoteAPI):
    """博客数据导入导出远程API客户端"""

    def export_data(self, filename: Optional[str] = None) -> Dict[str, Any]:
        """
        导出所有数据

        Args:
            filename: 保存文件名，如果为None则自动生成

        Returns:
            导出的数据字典
        """
        endpoint = "/api/root/export/data"
        response = self._request("GET", endpoint)

        data = response.json()

        # 如果指定了保存路径，保存到文件
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"blog_dump_{timestamp}.json"

        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        return data

    def import_data(self, file_path: str) -> Dict[str, Any]:
        """
        导入数据文件

        Args:
            file_path: 要导入的数据文件路径

        Returns:
            导入结果
        """
        endpoint = "/api/root/import/data"

        is_ok = self.validate_import_file(file_path)
        if not is_ok:
            raise Exception(f"备份文件验证失败")

        with open(file_path, 'rb') as f:
            files = {'file': (Path(file_path).name, f, 'application/json')}

            # 对于文件上传，需要移除Content-Type头，requests会自动设置
            headers = {k: v for k, v in self.headers.items() if k != 'Content-Type'}
            response = self._request("POST", endpoint, files=files, headers=headers)

        result = response.json()
        return result

    def validate_import_file(self, file_path: str) -> bool:
        """
        验证导入文件格式

        Args:
            file_path: 要验证的文件路径

        Returns:
            验证结果
        """
        endpoint = "/api/root/validate"

        with open(file_path, 'rb') as f:
            files = {'file': (Path(file_path).name, f, 'application/json')}

            # 对于文件上传，需要移除Content-Type头
            headers = {k: v for k, v in self.headers.items() if k != 'Content-Type'}
            response = self._request("POST", endpoint, files=files, headers=headers)

        result = response.json()

        if result.get('valid', False):
            return True
        else:
            return False

    def export_static(self, filename: Optional[str] = None) -> str:
        """
        导出静态文件为ZIP

        Args:
            filename: 保存文件名，如果为None则自动生成

        Returns:
            保存的文件路径
        """
        endpoint = "/api/root/export/static"
        response = self._request("GET", endpoint, stream=True)

        # 处理文件名
        if not filename:
            # 从Content-Disposition头获取文件名，或使用默认名
            content_disposition = response.headers.get('Content-Disposition', '')
            if 'filename=' in content_disposition:
                filename = content_disposition.split('filename=')[1].strip('"')
            else:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"static_files_{timestamp}.zip"

        # 保存文件
        with open(filename, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)

        file_size = os.path.getsize(filename)

        return {"filename":filename,"size":file_size}

    def import_static(self, file_path: str) -> Dict[str, Any]:
        """
        导入静态文件ZIP

        Args:
            file_path: 要导入的ZIP文件路径

        Returns:
            导入结果
        """
        endpoint = "/api/root/import/static"

        with open(file_path, 'rb') as f:
            files = {'file': (Path(file_path).name, f, 'application/zip')}

            # 对于文件上传，需要移除Content-Type头
            headers = {k: v for k, v in self.headers.items() if k != 'Content-Type'}
            response = self._request("POST", endpoint, files=files, headers=headers)

        result = response.json()
        return result

    def backup_all(self, backup_dir: str = "backups") -> Dict[str, str]:
        """
        完整备份（数据 + 静态文件），使用固定文件名，只保留最新备份

        Args:
            backup_dir: 备份目录

        Returns:
            包含两个备份文件路径的字典
        """
        backup_path = Path(backup_dir)
        backup_path.mkdir(exist_ok=True)

        # 固定文件名
        data_file = backup_path / "blog_data.json"
        static_file = backup_path / "blog_static.zip"

        # 备份数据
        self.export_data(str(data_file))

        # 备份静态文件
        self.export_static(str(static_file))

        return {
            "data": str(data_file),
            "static": str(static_file)
        }

    def restore_all(self, backup_dir: str = "backups") -> Dict[str, Any]:
        """
        从备份目录恢复完整备份（数据 + 静态文件）

        Args:
            backup_dir: 备份目录

        Returns:
            包含两个恢复结果的字典

        Raises:
            Exception: 如果备份目录中没有找到正确的备份文件
        """
        backup_path = Path(backup_dir)

        # 检查备份目录是否存在
        if not backup_path.exists():
            raise Exception(f"备份目录不存在: {backup_dir}")

        # 检查备份目录中的文件
        json_files = list(backup_path.glob("*.json"))
        zip_files = list(backup_path.glob("*.zip"))

        # 验证文件数量
        if len(json_files) != 1 or len(zip_files) != 1:
            raise Exception(
                f"备份目录中必须包含一个JSON文件和一个ZIP文件。"
                f"当前: JSON文件: {len(json_files)}个, ZIP文件: {len(zip_files)}个"
            )

        data_file = json_files[0]
        static_file = zip_files[0]

        # 恢复数据
        data_result = self.import_data(str(data_file))

        # 恢复静态文件
        static_result = self.import_static(str(static_file))

        return {
            "data": data_result,
            "static": static_result
        }

# 使用示例
if __name__ == "__main__":
    # 初始化认证 API 客户端
    auth_api = AuthAPI(base_url="http://hon-ker.cn",api_key = "123456")

    try:
        # 登录获取 API Key
        # login_result = auth_api.login("clay", "5Lit5Zu912138#")
        # print("登录结果:", login_result)
        # api_key = login_result.get("api_key","")
        # print("==",api_key,"==")

        # 获取网站元数据
        meta_info = auth_api.get_meta_info()
        print("元数据:", meta_info)

        # 刷新 API Key
        refresh_result = auth_api.refresh_api_key()
        print("刷新结果:", refresh_result)

    except Exception as e:
        print(f"操作失败: {e}")
