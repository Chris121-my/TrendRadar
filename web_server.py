# coding=utf-8
"""
TrendRadar Web Server
提供HTML网页访问和API端点
"""

import os
import sys
import threading
import time
import webbrowser
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import json

# 添加项目根目录到路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from main import NewsAnalyzer, CONFIG

# 全局变量，用于跟踪任务状态
task_status = {
    "running": False,
    "last_run_time": None,
    "last_result": None,
    "error": None
}

task_lock = threading.Lock()


# 确保目录存在
def ensure_directory_exists(directory):
    """确保目录存在"""
    Path(directory).mkdir(parents=True, exist_ok=True)


class WebRequestHandler(BaseHTTPRequestHandler):
    """HTTP请求处理器"""
    
    def do_GET(self):
        """处理GET请求"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        if path == '/' or path == '/index.html':
            self.serve_index()
        elif path == '/api/status':
            self.serve_status()
        elif path == '/api/trigger':
            self.serve_trigger()
        elif path.startswith('/output/'):
            self.serve_static_file(path)
        else:
            self.send_error(404, "Not Found")
    
    def do_POST(self):
        """处理POST请求"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        if path == '/api/trigger':
            self.serve_trigger()
        else:
            self.send_error(404, "Not Found")
    
    def serve_index(self):
        """提供index.html"""
        index_path = Path("index.html")
        if index_path.exists():
            with open(index_path, 'r', encoding='utf-8') as f:
                content = f.read()
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(content.encode('utf-8'))))
            self.end_headers()
            self.wfile.write(content.encode('utf-8'))
        else:
            self.send_error(404, "index.html not found")
    
    def serve_static_file(self, path):
        """提供静态文件"""
        # 移除 /output/ 前缀
        file_path = Path(path.lstrip('/'))
        if file_path.exists() and file_path.is_file():
            with open(file_path, 'rb') as f:
                content = f.read()
            
            # 根据文件扩展名设置Content-Type
            ext = file_path.suffix.lower()
            content_types = {
                '.html': 'text/html; charset=utf-8',
                '.css': 'text/css; charset=utf-8',
                '.js': 'application/javascript; charset=utf-8',
                '.txt': 'text/plain; charset=utf-8',
                '.json': 'application/json; charset=utf-8',
                '.png': 'image/png',
                '.jpg': 'image/jpeg',
                '.jpeg': 'image/jpeg',
                '.gif': 'image/gif',
            }
            
            content_type = content_types.get(ext, 'application/octet-stream')
            
            self.send_response(200)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(content)))
            self.end_headers()
            self.wfile.write(content)
        else:
            self.send_error(404, "File not found")
    
    def serve_status(self):
        """提供任务状态API"""
        with task_lock:
            status_data = {
                "running": task_status["running"],
                "last_run_time": task_status["last_run_time"],
                "error": task_status["error"]
            }
        
        response = json.dumps(status_data, ensure_ascii=False, indent=2)
        self.send_response(200)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-Length', str(len(response.encode('utf-8'))))
        self.end_headers()
        self.wfile.write(response.encode('utf-8'))
    
    def serve_trigger(self):
        """触发重新爬取任务"""
        global task_status
        
        with task_lock:
            if task_status["running"]:
                response_data = {
                    "success": False,
                    "message": "任务正在运行中，请稍后再试",
                    "running": True
                }
            else:
                # 启动新任务
                task_status["running"] = True
                task_status["error"] = None
                thread = threading.Thread(target=run_analysis_task, daemon=True)
                thread.start()
                
                response_data = {
                    "success": True,
                    "message": "任务已启动",
                    "running": True
                }
        
        response = json.dumps(response_data, ensure_ascii=False, indent=2)
        self.send_response(200)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-Length', str(len(response.encode('utf-8'))))
        self.end_headers()
        self.wfile.write(response.encode('utf-8'))
    
    def log_message(self, format, *args):
        """重写日志输出格式"""
        print(f"[WebServer] {format % args}")


def run_analysis_task():
    """在后台线程中运行分析任务"""
    global task_status
    
    try:
        print("[WebServer] 开始运行分析任务...")
        # 确保输出目录存在
        ensure_directory_exists("output")
        
        analyzer = NewsAnalyzer()
        analyzer.run()
        
        with task_lock:
            task_status["running"] = False
            task_status["last_run_time"] = time.strftime("%Y-%m-%d %H:%M:%S")
            task_status["error"] = None
            print(f"[WebServer] 分析任务完成: {task_status['last_run_time']}")
    except Exception as e:
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        with task_lock:
            task_status["running"] = False
            task_status["error"] = error_msg
            print(f"[WebServer] 分析任务出错: {error_msg}")


def get_local_ip():
    """获取本机IP地址"""
    import socket
    try:
        # 连接到一个远程地址来获取本机IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


def run_server(host='0.0.0.0', port=8080, open_browser=True):
    """
    启动Web服务器
    
    Args:
        host: 监听地址，默认 0.0.0.0（允许外部访问）
        port: 监听端口，默认 8080
        open_browser: 是否自动打开浏览器
    """
    server_address = (host, port)
    httpd = HTTPServer(server_address, WebRequestHandler)
    
    local_ip = get_local_ip()
    
    print("=" * 60)
    print("  TrendRadar Web Server")
    print("=" * 60)
    print(f"  本地访问: http://localhost:{port}")
    print(f"  局域网访问: http://{local_ip}:{port}")
    print(f"  外部访问: http://{host}:{port} (需要配置防火墙)")
    print()
    print("  功能:")
    print("  - 查看最新报告: http://localhost:{}/".format(port))
    print("  - 查看状态API: http://localhost:{}/api/status".format(port))
    print("  - 触发新任务: http://localhost:{}/api/trigger".format(port))
    print()
    print("  提示: 按 Ctrl+C 停止服务")
    print("=" * 60)
    print()
    
    if open_browser:
        # 延迟打开浏览器，确保服务器已启动
        threading.Timer(1.0, lambda: webbrowser.open(f'http://localhost:{port}')).start()
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[WebServer] 正在关闭服务器...")
        httpd.shutdown()
        print("[WebServer] 服务器已关闭")


if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='TrendRadar Web Server')
    parser.add_argument('--host', default='0.0.0.0', help='监听地址，默认 0.0.0.0')
    parser.add_argument('--port', type=int, default=8080, help='监听端口，默认 8080')
    parser.add_argument('--no-browser', action='store_true', help='不自动打开浏览器')
    
    args = parser.parse_args()
    
    run_server(host=args.host, port=args.port, open_browser=not args.no_browser)

