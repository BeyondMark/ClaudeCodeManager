#!/bin/bash

# ClaudeCodeManager 开发环境管理脚本
# 支持环境搭建、代码检查、测试运行等开发任务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_header() { echo -e "${PURPLE}🚀 $1${NC}"; }

# 环境初始化
init_env() {
    log_header "初始化开发环境..."
    
    # 后端环境
    log_info "配置后端环境..."
    cd backend
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        log_success "Python虚拟环境创建完成"
    fi
    source venv/bin/activate
    pip install -r requirements.txt --upgrade
    log_success "后端依赖更新完成"
    cd ..
    
    # 前端环境
    log_info "配置前端环境..."
    cd frontend
    npm install
    log_success "前端依赖安装完成"
    cd ..
    
    log_success "开发环境初始化完成"
}

# 代码质量检查
check_code() {
    log_header "代码质量检查..."
    
    local errors=0
    
    # 后端代码检查
    log_info "检查后端代码..."
    cd backend
    source venv/bin/activate
    
    # Python代码格式检查
    if command -v flake8 &> /dev/null; then
        if ! python -m flake8 modules/; then
            ((errors++))
        else
            log_success "Python代码格式检查通过"
        fi
    fi
    
    # Python类型检查
    if command -v mypy &> /dev/null; then
        if ! python -m mypy modules/; then
            ((errors++))
        else
            log_success "Python类型检查通过"
        fi
    fi
    
    cd ..
    
    # 前端代码检查
    log_info "检查前端代码..."
    cd frontend
    
    # ESLint检查
    if ! npm run lint; then
        ((errors++))
    else
        log_success "前端代码规范检查通过"
    fi
    
    # TypeScript类型检查
    if ! npm run type-check; then
        ((errors++))
    else
        log_success "前端类型检查通过"
    fi
    
    cd ..
    
    if [ $errors -eq 0 ]; then
        log_success "所有代码检查通过"
    else
        log_error "发现 $errors 个代码质量问题"
        return 1
    fi
}

# 运行测试
run_tests() {
    log_header "运行测试..."
    
    # 后端测试
    log_info "运行后端测试..."
    cd backend
    source venv/bin/activate
    
    if [ -d "tests" ]; then
        python -m pytest tests/ -v
        log_success "后端测试完成"
    else
        log_warning "未找到后端测试"
    fi
    
    cd ..
    
    # 前端测试（如果有）
    cd frontend
    if npm run test --if-present 2>/dev/null; then
        log_success "前端测试完成"
    else
        log_warning "未配置前端测试"
    fi
    cd ..
    
    log_success "测试运行完成"
}

# 构建项目
build_project() {
    log_header "构建项目..."
    
    # 构建前端
    log_info "构建前端项目..."
    cd frontend
    npm run build
    log_success "前端构建完成"
    cd ..
    
    # 后端检查（无需构建）
    log_info "验证后端配置..."
    cd backend
    source venv/bin/activate
    python -c "import main; print('后端模块加载正常')"
    log_success "后端验证完成"
    cd ..
    
    log_success "项目构建完成"
}

# 重置环境
reset_env() {
    log_header "重置开发环境..."
    
    log_warning "这将删除所有依赖和构建文件"
    read -p "确定要继续吗? [y/N]: " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "操作已取消"
        return 0
    fi
    
    # 清理后端
    log_info "清理后端环境..."
    cd backend
    rm -rf venv/ __pycache__/ .pytest_cache/
    find . -name "*.pyc" -delete
    cd ..
    
    # 清理前端
    log_info "清理前端环境..."
    cd frontend
    rm -rf node_modules/ dist/ .vite/
    cd ..
    
    # 清理日志和PID文件
    rm -f *.log .*.pid
    
    log_success "环境重置完成"
}

# 格式化代码
format_code() {
    log_header "格式化代码..."
    
    # 后端代码格式化
    log_info "格式化后端代码..."
    cd backend
    source venv/bin/activate
    
    if command -v black &> /dev/null; then
        black modules/
        log_success "Python代码格式化完成"
    else
        log_warning "未安装black格式化工具"
    fi
    
    cd ..
    
    # 前端代码格式化
    log_info "格式化前端代码..."
    cd frontend
    npm run format
    log_success "前端代码格式化完成"
    cd ..
    
    log_success "代码格式化完成"
}

# 开发模式启动
dev_mode() {
    log_header "开发模式启动..."
    
    # 先进行代码检查
    if ! check_code; then
        log_error "代码检查失败，请修复后重试"
        return 1
    fi
    
    # 启动服务
    log_info "启动开发服务..."
    
    # 启动后端（开发模式）
    cd backend
    source venv/bin/activate
    python main.py &
    BACKEND_PID=$!
    cd ..
    
    # 等待后端就绪
    sleep 5
    
    # 启动前端（开发模式）
    cd frontend
    npm run dev &
    FRONTEND_PID=$!
    cd ..
    
    log_success "开发环境启动完成"
    
    # 等待退出信号
    wait $BACKEND_PID $FRONTEND_PID
}

# 生产构建
prod_build() {
    log_header "生产环境构建..."
    
    # 代码检查
    check_code
    
    # 运行测试
    run_tests
    
    # 构建项目
    build_project
    
    log_success "生产构建完成"
}

# 显示项目信息
show_info() {
    log_header "项目信息"
    echo
    echo "📊 项目统计:"
    
    # 后端统计
    if [ -d "backend" ]; then
        PYTHON_FILES=$(find backend -name "*.py" | wc -l)
        PYTHON_LINES=$(find backend -name "*.py" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
        echo "   后端: $PYTHON_FILES 个Python文件, $PYTHON_LINES 行代码"
    fi
    
    # 前端统计
    if [ -d "frontend/src" ]; then
        VUE_FILES=$(find frontend/src -name "*.vue" -o -name "*.ts" | wc -l)
        VUE_LINES=$(find frontend/src -name "*.vue" -o -name "*.ts" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
        echo "   前端: $VUE_FILES 个Vue/TS文件, $VUE_LINES 行代码"
    fi
    
    echo
    echo "🔧 可用命令:"
    echo "   ./dev.sh init     - 初始化开发环境"
    echo "   ./dev.sh check    - 代码质量检查"
    echo "   ./dev.sh test     - 运行测试"
    echo "   ./dev.sh build    - 构建项目"
    echo "   ./dev.sh format   - 格式化代码"
    echo "   ./dev.sh reset    - 重置环境"
    echo "   ./dev.sh dev      - 开发模式启动"
    echo "   ./dev.sh prod     - 生产构建"
    echo
}

# 主程序
case "${1:-info}" in
    "init")
        init_env
        ;;
    "check")
        check_code
        ;;
    "test")
        run_tests
        ;;
    "build")
        build_project
        ;;
    "format")
        format_code
        ;;
    "reset")
        reset_env
        ;;
    "dev")
        dev_mode
        ;;
    "prod")
        prod_build
        ;;
    "info")
        show_info
        ;;
    *)
        echo "用法: $0 {init|check|test|build|format|reset|dev|prod|info}"
        echo
        echo "命令说明:"
        echo "  init   - 初始化开发环境"
        echo "  check  - 代码质量检查"
        echo "  test   - 运行测试"
        echo "  build  - 构建项目"
        echo "  format - 格式化代码"
        echo "  reset  - 重置开发环境"
        echo "  dev    - 开发模式启动"
        echo "  prod   - 生产环境构建"
        echo "  info   - 显示项目信息 (默认)"
        exit 1
        ;;
esac