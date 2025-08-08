#!/bin/bash

# ClaudeCodeManager 智能启动脚本
# 支持依赖检查、环境配置、并行启动和优雅关闭

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# PID文件
BACKEND_PID_FILE=".backend.pid"
FRONTEND_PID_FILE=".frontend.pid"

# 日志函数
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

# 清理函数
cleanup() {
    log_info "正在关闭服务..."
    
    # 停止后端服务
    if [ -f "$BACKEND_PID_FILE" ]; then
        BACKEND_PID=$(cat "$BACKEND_PID_FILE")
        if ps -p "$BACKEND_PID" > /dev/null 2>&1; then
            kill "$BACKEND_PID" 2>/dev/null || true
            log_success "后端服务已停止 (PID: $BACKEND_PID)"
        fi
        rm -f "$BACKEND_PID_FILE"
    fi
    
    # 停止前端服务
    if [ -f "$FRONTEND_PID_FILE" ]; then
        FRONTEND_PID=$(cat "$FRONTEND_PID_FILE")
        if ps -p "$FRONTEND_PID" > /dev/null 2>&1; then
            kill "$FRONTEND_PID" 2>/dev/null || true
            log_success "前端服务已停止 (PID: $FRONTEND_PID)"
        fi
        rm -f "$FRONTEND_PID_FILE"
    fi
    
    # 杀死相关进程
    pkill -f "python.*main.py" 2>/dev/null || true
    pkill -f "npm.*run.*dev" 2>/dev/null || true
    
    log_success "ClaudeCodeManager 已完全关闭"
    exit 0
}

# 注册信号处理
trap cleanup SIGINT SIGTERM

# 检查依赖函数
check_dependencies() {
    log_header "检查系统依赖..."
    
    local missing_deps=()
    
    # 检查Python
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    else
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        log_success "Python 版本: $PYTHON_VERSION"
    fi
    
    # 检查Node.js和npm
    if ! command -v node &> /dev/null; then
        missing_deps+=("node")
    else
        NODE_VERSION=$(node --version)
        log_success "Node.js 版本: $NODE_VERSION"
    fi
    
    if ! command -v npm &> /dev/null; then
        missing_deps+=("npm")
    else
        NPM_VERSION=$(npm --version)
        log_success "npm 版本: $NPM_VERSION"
    fi
    
    # 检查Git（可选）
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | cut -d' ' -f3)
        log_success "Git 版本: $GIT_VERSION"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        log_info "请先安装缺少的依赖，然后重新运行脚本"
        exit 1
    fi
    
    log_success "所有依赖检查通过"
}

# 检查端口占用
check_ports() {
    log_info "检查端口占用..."
    
    # 检查50000端口（后端）
    if lsof -Pi :50000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "端口50000已被占用，将尝试终止相关进程"
        pkill -f ":50000" 2>/dev/null || true
        sleep 2
    fi
    
    # 检查50001端口（前端）
    if lsof -Pi :50001 -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "端口50001已被占用，将尝试终止相关进程"
        pkill -f ":50001" 2>/dev/null || true
        sleep 2
    fi
    
    log_success "端口检查完成"
}

# 设置后端环境
setup_backend() {
    log_header "配置后端环境..."
    
    cd backend
    
    # 创建虚拟环境
    if [ ! -d "venv" ]; then
        log_info "创建Python虚拟环境..."
        python3 -m venv venv
        log_success "虚拟环境创建完成"
    fi
    
    # 激活虚拟环境
    source venv/bin/activate
    
    # 安装/更新依赖
    log_info "安装Python依赖..."
    pip install -r requirements.txt --quiet
    log_success "Python依赖安装完成"
    
    cd ..
}

# 设置前端环境
setup_frontend() {
    log_header "配置前端环境..."
    
    cd frontend
    
    # 检查node_modules
    if [ ! -d "node_modules" ] || [ ! -f "node_modules/.package-lock.json" ]; then
        log_info "安装Node.js依赖..."
        npm install --silent
        log_success "Node.js依赖安装完成"
    else
        log_success "前端依赖已就绪"
    fi
    
    cd ..
}

# 启动后端服务
start_backend() {
    log_header "启动后端服务..."
    
    cd backend
    source venv/bin/activate
    
    # 后台启动后端
    nohup python main.py > ../backend.log 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "../$BACKEND_PID_FILE"
    
    log_info "后端服务启动中... (PID: $BACKEND_PID)"
    
    # 等待后端启动
    log_info "等待后端服务就绪..."
    for i in {1..30}; do
        if curl -s http://localhost:50000/health > /dev/null 2>&1; then
            log_success "后端服务启动成功 → http://localhost:50000"
            break
        fi
        
        if [ $i -eq 30 ]; then
            log_error "后端启动超时，请检查日志: backend.log"
            cleanup
            exit 1
        fi
        
        sleep 1
        echo -n "."
    done
    echo
    
    cd ..
}

# 启动前端服务
start_frontend() {
    log_header "启动前端服务..."
    
    cd frontend
    
    # 后台启动前端
    nohup npm run dev > ../frontend.log 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > "../$FRONTEND_PID_FILE"
    
    log_info "前端服务启动中... (PID: $FRONTEND_PID)"
    
    # 等待前端启动
    log_info "等待前端服务就绪..."
    for i in {1..60}; do
        if curl -s http://localhost:50001 > /dev/null 2>&1; then
            log_success "前端服务启动成功 → http://localhost:50001"
            break
        fi
        
        if [ $i -eq 60 ]; then
            log_error "前端启动超时，请检查日志: frontend.log"
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

# 显示服务信息
show_services() {
    echo
    log_header "🎉 ClaudeCodeManager 启动完成!"
    echo
    echo "📱 服务地址:"
    echo -e "   前端界面: ${CYAN}http://localhost:50001${NC}"
    echo -e "   后端API:  ${CYAN}http://localhost:50000${NC}"
    echo -e "   API文档:  ${CYAN}http://localhost:50000/docs${NC}"
    echo -e "   ReDoc:    ${CYAN}http://localhost:50000/redoc${NC}"
    echo
    echo "📊 服务状态:"
    echo -e "   后端: ${GREEN}运行中${NC} (PID: $(cat $BACKEND_PID_FILE 2>/dev/null || echo 'N/A'))"
    echo -e "   前端: ${GREEN}运行中${NC} (PID: $(cat $FRONTEND_PID_FILE 2>/dev/null || echo 'N/A'))"
    echo
    echo "📝 日志文件:"
    echo "   后端日志: backend.log"
    echo "   前端日志: frontend.log"
    echo
    echo "🔧 常用操作:"
    echo "   查看后端日志: tail -f backend.log"
    echo "   查看前端日志: tail -f frontend.log"
    echo "   重启服务: ./start.sh restart"
    echo "   停止服务: ./start.sh stop"
    echo
    echo -e "${YELLOW}按 Ctrl+C 停止所有服务${NC}"
    echo
}

# 检查服务状态
check_services() {
    log_info "检查服务状态..."
    
    # 检查后端
    if curl -s http://localhost:50000/health > /dev/null 2>&1; then
        log_success "后端服务正常"
    else
        log_error "后端服务异常"
        return 1
    fi
    
    # 检查前端
    if curl -s http://localhost:50001 > /dev/null 2>&1; then
        log_success "前端服务正常"
    else
        log_error "前端服务异常"
        return 1
    fi
    
    return 0
}

# 停止服务
stop_services() {
    log_header "停止服务..."
    cleanup
}

# 重启服务
restart_services() {
    log_header "重启服务..."
    stop_services
    sleep 3
    main
}

# 主函数
main() {
    # 清理旧的PID文件
    rm -f "$BACKEND_PID_FILE" "$FRONTEND_PID_FILE"
    
    # 执行启动流程
    check_dependencies
    check_ports
    setup_backend
    setup_frontend
    start_backend
    start_frontend
    show_services
    
    # 保持脚本运行，监听退出信号
    while true; do
        sleep 5
        
        # 检查服务是否还在运行
        if ! ps -p "$(cat $BACKEND_PID_FILE 2>/dev/null)" > /dev/null 2>&1; then
            log_error "后端服务意外停止"
            cleanup
            exit 1
        fi
        
        if ! ps -p "$(cat $FRONTEND_PID_FILE 2>/dev/null)" > /dev/null 2>&1; then
            log_error "前端服务意外停止"
            cleanup
            exit 1
        fi
    done
}

# 命令行参数处理
case "${1:-start}" in
    "start")
        main
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        restart_services
        ;;
    "status")
        if check_services; then
            log_success "所有服务运行正常"
        else
            log_error "部分服务异常"
            exit 1
        fi
        ;;
    "logs")
        log_info "实时查看日志 (Ctrl+C 退出):"
        tail -f backend.log frontend.log
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|logs}"
        echo
        echo "命令说明:"
        echo "  start   - 启动所有服务 (默认)"
        echo "  stop    - 停止所有服务"
        echo "  restart - 重启所有服务"
        echo "  status  - 检查服务状态"
        echo "  logs    - 查看实时日志"
        exit 1
        ;;
esac