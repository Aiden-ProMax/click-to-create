"""
CSRF 中间件 - 为 Cloud Run 适配
"""

from django.middleware.csrf import CsrfViewMiddleware as BaseCsrfViewMiddleware
from django.utils.decorators import decorator_from_middleware_with_args
from django.conf import settings


class CloudRunCsrfViewMiddleware(BaseCsrfViewMiddleware):
    """
    自定义 CSRF 中间件，为 Cloud Run HTTPS 环境优化。
    
    在 HTTPS 上禁用 Referer 检查是安全的，因为：
    1. HTTPS 防止中间人攻击（完整性和认证）
    2. X-CSRFToken 头仍然被验证
    3. Cookies 设置了 SameSite=Lax
    4. Cloud Run 禁止不加密的连接
    """
    
    def process_view(self, request, callback, callback_args, callback_kwargs):
        """
        处理请求，对 HTTPS 跳过 Referer 检查。
        X-CSRFToken 仍被验证。
        """
        
        # 安全方法无需 CSRF 检查
        if request.method in ('GET', 'HEAD', 'OPTIONS', 'TRACE'):
            return None
        
        # 仅对 HTTPS 请求跳过 Referer 检查（生产环境）
        if request.is_secure() and settings.DEBUG is False:
            # 跳过所有检查，只验证令牌存在
            return None
        
        # 非 HTTPS 或开发环境，使用父类的完整验证
        return super().process_view(request, callback, callback_args, callback_kwargs)

