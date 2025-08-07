@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: ClaudeCodeManager Windows启动脚本
:: 支持依赖检查、环境配置、并行启动和优雅关闭

set "BACKEND_PID_FILE=.backend.pid"
set "FRONTEND_PID_FILE=.frontend.pid"

:: 颜色定义（Windows 10+）
set "ESC="
set "RED=%ESC%[31m"
set "GREEN=%ESC%[32m"
set "YELLOW=%ESC%[33m"
set "BLUE=%ESC%[34m"
set "PURPLE=%ESC%[35m"
set "CYAN=%ESC%[36m"
set "NC=%ESC%[0m"

:: 主函数
if "%1"=="" goto :main
if "%1"=="start" goto :main
if "%1"=="stop" goto :stop_services
if "%1"=="restart" goto :restart_services
if "%1"=="status" goto :check_services_status
if "%1"=="logs" goto :show_logs
goto :show_usage

:main
call :cleanup_old_processes
call :check_dependencies
call :check_ports
call :setup_backend
call :setup_frontend
call :start_backend
call :start_frontend
call :show_services
call :monitor_services
goto :eof

:: 日志函数
:log_info
echo %BLUE%ℹ️  %~1%NC%
goto :eof

:log_success
echo %GREEN%✅ %~1%NC%
goto :eof

:log_warning
echo %YELLOW%⚠️  %~1%NC%
goto :eof

:log_error
echo %RED%❌ %~1%NC%
goto :eof

:log_header
echo %PURPLE%🚀 %~1%NC%
goto :eof

:: 清理旧进程
:cleanup_old_processes
call :log_info "清理旧进程..."
taskkill /f /im python.exe >nul 2>&1 || true
taskkill /f /im node.exe >nul 2>&1 || true
if exist "%BACKEND_PID_FILE%" del "%BACKEND_PID_FILE%" >nul 2>&1
if exist "%FRONTEND_PID_FILE%" del "%FRONTEND_PID_FILE%" >nul 2>&1
call :log_success "进程清理完成"
goto :eof

:: 检查依赖
:check_dependencies
call :log_header "检查系统依赖..."

:: 检查Python
where python >nul 2>&1
if !errorlevel! neq 0 (
    call :log_error "Python未安装或不在PATH中"
    pause
    exit /b 1
) else (
    for /f "tokens=2" %%v in ('python --version 2^>^&1') do (
        call :log_success "Python 版本: %%v"
    )
)

:: 检查Node.js
where node >nul 2>&1
if !errorlevel! neq 0 (
    call :log_error "Node.js未安装或不在PATH中"
    pause
    exit /b 1
) else (
    for /f %%v in ('node --version') do (
        call :log_success "Node.js 版本: %%v"
    )
)

:: 检查npm
where npm >nul 2>&1
if !errorlevel! neq 0 (
    call :log_error "npm未安装或不在PATH中"
    pause
    exit /b 1
) else (
    for /f %%v in ('npm --version') do (
        call :log_success "npm 版本: %%v"
    )
)

call :log_success "所有依赖检查通过"
goto :eof

:: 检查端口占用
:check_ports
call :log_info "检查端口占用..."

:: 检查端口8000
netstat -an | find "8000" | find "LISTENING" >nul 2>&1
if !errorlevel! equ 0 (
    call :log_warning "端口8000已被占用，将尝试释放"
    for /f "tokens=5" %%a in ('netstat -ano ^| find "8000" ^| find "LISTENING"') do (
        taskkill /f /pid %%a >nul 2>&1 || true
    )
    timeout /t 2 >nul
)

:: 检查端口5173
netstat -an | find "5173" | find "LISTENING" >nul 2>&1
if !errorlevel! equ 0 (
    call :log_warning "端口5173已被占用，将尝试释放"
    for /f "tokens=5" %%a in ('netstat -ano ^| find "5173" ^| find "LISTENING"') do (
        taskkill /f /pid %%a >nul 2>&1 || true
    )
    timeout /t 2 >nul
)

call :log_success "端口检查完成"
goto :eof

:: 设置后端环境
:setup_backend
call :log_header "配置后端环境..."

cd backend

:: 创建虚拟环境
if not exist "venv" (
    call :log_info "创建Python虚拟环境..."
    python -m venv venv
    call :log_success "虚拟环境创建完成"
)

:: 激活虚拟环境并安装依赖
call :log_info "安装Python依赖..."
call venv\Scripts\activate.bat
pip install -r requirements.txt --quiet
call :log_success "Python依赖安装完成"

cd ..
goto :eof

:: 设置前端环境
:setup_frontend
call :log_header "配置前端环境..."

cd frontend

:: 检查并安装Node.js依赖
if not exist "node_modules" (
    call :log_info "安装Node.js依赖..."
    npm install --silent
    call :log_success "Node.js依赖安装完成"
) else (
    call :log_success "前端依赖已就绪"
)

cd ..
goto :eof

:: 启动后端服务
:start_backend
call :log_header "启动后端服务..."

cd backend
call venv\Scripts\activate.bat

:: 后台启动后端
start /b python main.py > ..\backend.log 2>&1

:: 等待后端启动
call :log_info "等待后端服务就绪..."
set /a count=0
:wait_backend
set /a count+=1
curl -s http://localhost:8000/health >nul 2>&1
if !errorlevel! equ 0 (
    call :log_success "后端服务启动成功 → http://localhost:8000"
    goto :backend_ready
)

if !count! geq 30 (
    call :log_error "后端启动超时，请检查日志: backend.log"
    pause
    exit /b 1
)

timeout /t 1 >nul
echo|set /p="."
goto :wait_backend

:backend_ready
echo.
cd ..
goto :eof

:: 启动前端服务
:start_frontend
call :log_header "启动前端服务..."

cd frontend

:: 后台启动前端
start /b npm run dev > ..\frontend.log 2>&1

:: 等待前端启动
call :log_info "等待前端服务就绪..."
set /a count=0
:wait_frontend
set /a count+=1
curl -s http://localhost:5173 >nul 2>&1
if !errorlevel! equ 0 (
    call :log_success "前端服务启动成功 → http://localhost:5173"
    goto :frontend_ready
)

if !count! geq 60 (
    call :log_error "前端启动超时，请检查日志: frontend.log"
    pause
    exit /b 1
)

set /a mod=count %% 10
if !mod! equ 0 (
    echo|set /p=" !count!s"
) else (
    echo|set /p="."
)

timeout /t 1 >nul
goto :wait_frontend

:frontend_ready
echo.
cd ..
goto :eof

:: 显示服务信息
:show_services
echo.
call :log_header "🎉 ClaudeCodeManager 启动完成!"
echo.
echo 📱 服务地址:
echo    前端界面: %CYAN%http://localhost:5173%NC%
echo    后端API:  %CYAN%http://localhost:8000%NC%
echo    API文档:  %CYAN%http://localhost:8000/docs%NC%
echo    ReDoc:    %CYAN%http://localhost:8000/redoc%NC%
echo.
echo 📝 日志文件:
echo    后端日志: backend.log
echo    前端日志: frontend.log
echo.
echo 🔧 常用操作:
echo    查看后端日志: type backend.log
echo    查看前端日志: type frontend.log
echo    重启服务: start.bat restart
echo    停止服务: start.bat stop
echo    检查状态: start.bat status
echo.
echo %YELLOW%按 Ctrl+C 停止所有服务%NC%
echo.
goto :eof

:: 监控服务
:monitor_services
:monitor_loop
timeout /t 5 >nul

:: 检查进程是否还在运行
tasklist | find "python.exe" >nul 2>&1
if !errorlevel! neq 0 (
    call :log_error "后端服务意外停止"
    pause
    exit /b 1
)

tasklist | find "node.exe" >nul 2>&1
if !errorlevel! neq 0 (
    call :log_error "前端服务意外停止"
    pause
    exit /b 1
)

goto :monitor_loop

:: 检查服务状态
:check_services_status
call :log_info "检查服务状态..."

curl -s http://localhost:8000/health >nul 2>&1
if !errorlevel! equ 0 (
    call :log_success "后端服务正常"
) else (
    call :log_error "后端服务异常"
    exit /b 1
)

curl -s http://localhost:5173 >nul 2>&1
if !errorlevel! equ 0 (
    call :log_success "前端服务正常"
) else (
    call :log_error "前端服务异常"
    exit /b 1
)

call :log_success "所有服务运行正常"
goto :eof

:: 停止服务
:stop_services
call :log_header "停止服务..."
taskkill /f /im python.exe >nul 2>&1 || true
taskkill /f /im node.exe >nul 2>&1 || true
if exist "%BACKEND_PID_FILE%" del "%BACKEND_PID_FILE%" >nul 2>&1
if exist "%FRONTEND_PID_FILE%" del "%FRONTEND_PID_FILE%" >nul 2>&1
call :log_success "所有服务已停止"
goto :eof

:: 重启服务
:restart_services
call :log_header "重启服务..."
call :stop_services
timeout /t 3 >nul
goto :main

:: 查看日志
:show_logs
call :log_info "显示最新日志..."
if exist "backend.log" (
    echo.
    echo === 后端日志 ===
    type backend.log | more
)
if exist "frontend.log" (
    echo.
    echo === 前端日志 ===
    type frontend.log | more
)
goto :eof

:: 显示用法
:show_usage
echo 用法: %0 {start^|stop^|restart^|status^|logs}
echo.
echo 命令说明:
echo   start   - 启动所有服务 (默认)
echo   stop    - 停止所有服务
echo   restart - 重启所有服务
echo   status  - 检查服务状态
echo   logs    - 查看服务日志
echo.
pause
goto :eof