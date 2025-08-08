#!/bin/bash

# ClaudeCodeManager 调试启动脚本
# 支持代码动态重载、调试端口、详细日志、快速重启

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# PID文件
BACKEND_PID_FILE=".debug-backend.pid"
FRONTEND_PID_FILE=".debug-frontend.pid"

# 日志函数
log_info() { echo -e "${BLUE}🔧 $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_header() { echo -e "${PURPLE}🚀 $1${NC}"; }

# 清理函数
cleanup() {
    log_info "正在关闭调试服务..."
    
    # 停止后端服务
    if [ -f "$BACKEND_PID_FILE" ]; then
        BACKEND_PID=$(cat "$BACKEND_PID_FILE")
        if ps -p "$BACKEND_PID" > /dev/null 2>&1; then
            kill "$BACKEND_PID" 2>/dev/null || true
            log_success "后端调试服务已停止 (PID: $BACKEND_PID)"
        fi
        rm -f "$BACKEND_PID_FILE"
    fi
    
    # 停止前端服务
    if [ -f "$FRONTEND_PID_FILE" ]; then
        FRONTEND_PID=$(cat "$FRONTEND_PID_FILE")
        if ps -p "$FRONTEND_PID" > /dev/null 2>&1; then
            kill "$FRONTEND_PID" 2>/dev/null || true
            log_success "前端调试服务已停止 (PID: $FRONTEND_PID)"
        fi
        rm -f "$FRONTEND_PID_FILE"
    fi
    
    # 清理相关进程
    pkill -f "python.*--reload" 2>/dev/null || true
    pkill -f "nodemon" 2>/dev/null || true
    pkill -f "vite.*--mode development" 2>/dev/null || true
    
    log_success "调试环境已完全关闭"
    exit 0
}

# 注册信号处理
trap cleanup SIGINT SIGTERM

# 检查依赖
check_dependencies() {
    log_header "检查调试环境依赖..."
    
    local missing_deps=()
    
    # 检查Python
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    else
        log_success "Python $(python3 --version | cut -d' ' -f2) ✓"
    fi
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        missing_deps+=("node")
    else
        log_success "Node.js $(node --version) ✓"
    fi
    
    # 检查npm
    if ! command -v npm &> /dev/null; then
        missing_deps+=("npm")
    else
        log_success "npm $(npm --version) ✓"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        exit 1
    fi
}

# 检查调试端口占用
check_debug_ports() {
    log_info "检查调试端口占用..."
    
    # 检查50000端口（后端API）
    if lsof -Pi :50000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "端口50000已被占用，正在强制终止..."
        # 获取占用端口的进程并强制终止
        local pids=$(lsof -Pi :50000 -sTCP:LISTEN -t)
        for pid in $pids; do
            kill -9 $pid 2>/dev/null || true
        done
        sleep 3
        # 再次检查
        if lsof -Pi :50000 -sTCP:LISTEN -t >/dev/null 2>&1; then
            log_error "无法释放端口50000，请手动检查进程"
            exit 1
        fi
    fi
    
    # 检查50001端口（前端开发服务器）
    if lsof -Pi :50001 -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "端口50001已被占用，正在强制终止..."
        local pids=$(lsof -Pi :50001 -sTCP:LISTEN -t)
        for pid in $pids; do
            kill -9 $pid 2>/dev/null || true
        done
        sleep 3
        if lsof -Pi :50001 -sTCP:LISTEN -t >/dev/null 2>&1; then
            log_error "无法释放端口50001，请手动检查进程"
            exit 1
        fi
    fi
    
    # 检查9229端口（Node.js调试器）
    if lsof -Pi :9229 -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "调试端口9229已被占用，正在强制终止..."
        local pids=$(lsof -Pi :9229 -sTCP:LISTEN -t)
        for pid in $pids; do
            kill -9 $pid 2>/dev/null || true
        done
        sleep 2
    fi
    
    log_success "端口检查完成"
}

# 设置后端调试环境
setup_backend_debug() {
    log_header "配置后端调试环境..."
    
    cd backend
    
    # 激活虚拟环境
    if [ ! -d "venv" ]; then
        log_info "创建Python虚拟环境..."
        python3 -m venv venv
        log_success "虚拟环境创建完成"
    fi
    
    source venv/bin/activate
    
    # 安装依赖
    log_info "安装/更新Python依赖..."
    pip install -r requirements.txt --quiet
    log_success "Python依赖更新完成"
    
    cd ..
}

# 设置前端调试环境
setup_frontend_debug() {
    log_header "配置前端调试环境..."
    
    cd frontend
    
    # 检查并安装依赖
    if [ ! -d "node_modules" ] || [ ! -f "node_modules/.package-lock.json" ]; then
        log_info "安装Node.js依赖..."
        npm install --silent
        log_success "Node.js依赖安装完成"
    else
        log_success "前端依赖已就绪"
    fi
    
    cd ..
}

# 启动后端调试服务
start_backend_debug() {
    log_header "启动后端调试服务..."
    
    cd backend
    source venv/bin/activate
    
    # 设置环境变量
    export DEBUG=1
    export PYTHONUNBUFFERED=1
    
    # 使用uvicorn命令行直接启动，更稳定
    log_info "启动FastAPI调试服务器..."
    nohup uvicorn main:app \
        --host 0.0.0.0 \
        --port 50000 \
        --reload \
        --reload-include="*.py" \
        --reload-exclude="*.pyc" \
        --reload-exclude="__pycache__/*" \
        --reload-exclude="venv/*" \
        --reload-exclude="tests/*" \
        --log-level debug \
        --use-colors \
        --access-log > ../backend-debug.log 2>&1 &
    
    BACKEND_PID=$!
    echo $BACKEND_PID > "../$BACKEND_PID_FILE"
    
    log_info "后端调试服务启动中... (PID: $BACKEND_PID)"
    
    # 等待后端就绪
    log_info "等待后端服务就绪..."
    for i in {1..30}; do
        if curl -s http://localhost:50000/health > /dev/null 2>&1; then
            log_success "后端调试服务启动成功 → http://localhost:50000"
            log_info "调试信息:"
            echo "  • API接口: ${CYAN}http://localhost:50000${NC}"
            echo "  • 健康检查: ${CYAN}http://localhost:50000/health${NC}"
            echo "  • API文档: ${CYAN}http://localhost:50000/docs${NC}"
            echo "  • 自动重载: ${GREEN}已启用${NC} (.py文件)"
            echo "  • 调试日志: ${GREEN}已启用${NC}"
            break
        fi
        
        if [ $i -eq 30 ]; then
            log_error "后端启动超时，请检查日志: backend-debug.log"
            cleanup
            exit 1
        fi
        
        sleep 1
        echo -n "."
    done
    echo
    
    cd ..
}

# 启动前端调试服务
start_frontend_debug() {
    log_header "启动前端调试服务..."
    
    cd frontend
    
    # 使用Vite的开发模式启动，支持HMR（Vite原生支持热更新，无需nodemon）
    log_info "启动Vite开发服务器..."
    
    # 创建vite配置以增强调试功能
    cat > vite.debug.config.ts << 'EOF'
import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

export default defineConfig({
  plugins: [
    vue(),
    vueDevTools()
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  server: {
    host: '0.0.0.0',
    port: 50001,
    strictPort: true,
    hmr: {
      overlay: true,
      host: '0.0.0.0'
    },
    watch: {
      usePolling: true,
      interval: 1000
    }
  },
  define: {
    __VUE_OPTIONS_API__: true,
    __VUE_PROD_DEVTOOLS__: false,
    __VUE_PROD_HYDRATION_MISMATCH_DETAILS__: false
  },
  css: {
    devSourcemap: true
  },
  build: {
    sourcemap: true
  }
})
EOF
    
    # 使用调试配置启动
    nohup npm run dev -- --config vite.debug.config.ts > ../frontend-debug.log 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > "../$FRONTEND_PID_FILE"
    
    log_info "前端调试服务启动中... (PID: $FRONTEND_PID)"
    
    # 等待前端就绪
    log_info "等待前端服务就绪..."
    for i in {1..60}; do
        if curl -s http://localhost:50001 > /dev/null 2>&1; then
            log_success "前端调试服务启动成功 → http://localhost:50001"
            log_info "调试信息:"
            echo "  • 开发服务器: ${CYAN}http://localhost:50001${NC}"
            echo "  • 热更新(HMR): ${GREEN}已启用${NC}"
            echo "  • Vue DevTools: ${GREEN}已启用${NC}"
            echo "  • 源码映射: ${GREEN}已启用${NC}"
            echo "  • 错误覆盖层: ${GREEN}已启用${NC}"
            break
        fi
        
        if [ $i -eq 60 ]; then
            log_error "前端启动超时，请检查日志: frontend-debug.log"
            cleanup
            exit 1
        fi
        
        sleep 1
        if [ $((i % 10)) -eq 0 ]; then
            echo -n " ${i}s"
        else
            echo -n "."
        fi
    done
    echo
    
    cd ..
}

# 安装调试工具
install_debug_tools() {
    log_header "安装调试工具..."
    
    # 后端调试工具
    cd backend
    source venv/bin/activate
    
    # 安装调试相关包
    log_info "安装Python调试工具..."
    pip install --quiet watchdog python-dotenv debugpy
    log_success "Python调试工具安装完成"
    
    cd ..
    
    # 前端调试工具（如果没有）
    cd frontend
    if ! npm list vite-plugin-vue-devtools &> /dev/null; then
        log_info "安装前端调试工具..."
        npm install --save-dev vite-plugin-vue-devtools --silent
        log_success "前端调试工具安装完成"
    fi
    cd ..
}

# 显示调试信息
show_debug_info() {
    echo
    log_header "🎉 调试环境启动完成!"
    echo
    echo "📱 服务地址:"
    echo -e "   前端界面: ${CYAN}http://localhost:50001${NC} (支持热更新)"
    echo -e "   后端API:  ${CYAN}http://localhost:50000${NC} (自动重载)"
    echo -e "   API文档:  ${CYAN}http://localhost:50000/docs${NC}"
    echo -e "   ReDoc:    ${CYAN}http://localhost:50000/redoc${NC}"
    echo
    echo "🔧 调试功能:"
    echo "   后端自动重载: ${GREEN}✓ 修改.py文件自动重启${NC}"
    echo "   前端热更新:   ${GREEN}✓ 实时预览代码变更${NC}"
    echo "   源码映射:     ${GREEN}✓ 浏览器调试支持${NC}"
    echo "   Vue DevTools: ${GREEN}✓ 组件调试工具${NC}"
    echo "   错误覆盖:     ${GREEN}✓ 编译错误显示${NC}"
    echo
    echo "📊 服务状态:"
    echo -e "   后端: ${GREEN}运行中${NC} (PID: $(cat $BACKEND_PID_FILE 2>/dev/null || echo 'N/A'))"
    echo -e "   前端: ${GREEN}运行中${NC} (PID: $(cat $FRONTEND_PID_FILE 2>/dev/null || echo 'N/A'))"
    echo
    echo "📝 日志文件:"
    echo "   后端日志: backend-debug.log"
    echo "   前端日志: frontend-debug.log"
    echo
    echo "🔧 调试技巧:"
    echo "   查看实时日志: tail -f backend-debug.log frontend-debug.log"
    echo "   重启后端: 修改任意.py文件保存"
    echo "   重启前端: 在浏览器按 ${CYAN}Ctrl+R${NC}"
    echo "   完全重启: ./debug.sh restart"
    echo
    echo -e "${YELLOW}按 Ctrl+C 停止所有调试服务${NC}"
    echo
}

# 监控服务状态
monitor_services() {
    while true; do
        sleep 5
        
        # 检查后端服务
        if ! ps -p "$(cat $BACKEND_PID_FILE 2>/dev/null)" > /dev/null 2>&1; then
            log_error "后端调试服务意外停止"
            cleanup
            exit 1
        fi
        
        # 检查前端服务
        if ! ps -p "$(cat $FRONTEND_PID_FILE 2>/dev/null)" > /dev/null 2>&1; then
            log_error "前端调试服务意外停止"
            cleanup
            exit 1
        fi
    done
}

# 显示实时日志
show_logs() {
    log_header "显示实时调试日志"
    echo "按 Ctrl+C 返回主菜单"
    echo
    tail -f backend-debug.log frontend-debug.log 2>/dev/null
}

# 重启服务
restart_services() {
    log_header "重启调试服务..."
    cleanup
    sleep 3
    main
}

# 主函数
main() {
    # 清理旧的PID文件
    rm -f "$BACKEND_PID_FILE" "$FRONTEND_PID_FILE"
    
    # 执行启动流程
    check_dependencies
    check_debug_ports
    install_debug_tools
    setup_backend_debug
    setup_frontend_debug
    start_backend_debug
    start_frontend_debug
    show_debug_info
    
    # 监控服务状态
    monitor_services
}

# 命令行参数处理
case "${1:-start}" in
    "start")
        main
        ;;
    "stop")
        cleanup
        ;;
    "restart")
        restart_services
        ;;
    "logs")
        show_logs
        ;;
    "install")
        check_dependencies
        install_debug_tools
        log_success "调试工具安装完成"
        ;;
    *)
        echo "用法: $0 {start|stop|restart|logs|install}"
        echo
        echo "命令说明:"
        echo "  start   - 启动调试环境 (默认)"
        echo "  stop    - 停止调试环境"
        echo "  restart - 重启调试环境"
        echo "  logs    - 查看实时日志"
        echo "  install - 安装调试工具"
        echo
        echo "调试特性:"
        echo "  • 后端自动重载 (修改.py文件)"
        echo "  • 前端热更新 (HMR)"
        echo "  • Vue DevTools 支持"
        echo "  • 源码映射调试"
        echo "  • 详细错误显示"
        exit 1
        ;;
esac