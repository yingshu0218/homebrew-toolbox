class Toolbox < Formula
  desc "个人工具箱集合 — 文档转换/EPUB/网络检测 (Flask 多工具整合)"
  homepage "https://github.com/yingshu0218/toolbox"
  url "https://github.com/yingshu0218/toolbox/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "e71efb5b265c9e046708f92c1b6346af78ea6c402c3f1a1baeb3824eabae6653"
  version "1.0.1"
  license "MIT"
  head "https://github.com/yingshu0218/toolbox.git", branch: "main"

  depends_on "python@3.12"
  depends_on "pandoc"

  def install
    port = ENV["TOOLBOX_PORT"] || "9053"
    libexec.install Dir["*"]
    py = Formula["python@3.12"].opt_bin/"python3.12"
    (bin/"toolbox").write <<~EOS
      #!/usr/bin/env bash
      set -u
      PY="#{py}"
      command -v "$PY" >/dev/null 2>&1 || PY="python3"
      ROOT="#{libexec}"
      PORT="#{port}"
      PID_FILE="$ROOT/toolbox.pid"
      LOG_FILE="/tmp/toolbox.log"
      export TOOLBOX_PORT="$PORT"
      export PYTHONPATH="$ROOT/site-packages"
      if [ "${1:-}" = "stop" ]; then
        [ -f "$PID_FILE" ] && kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE"; echo "Toolbox 已停止"; exit 0
      fi
      if [ "${1:-}" = "status" ]; then
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
          echo "运行中 (PID: $(cat "$PID_FILE")) → http://localhost:${PORT}"
        else echo "未运行"; fi; exit 0
      fi
      if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "已在运行 → http://localhost:${PORT}"
        open "http://localhost:${PORT}/" 2>/dev/null; exit 0
      fi
      if ! "$PY" -c "import flask" 2>/dev/null; then
        echo "首次运行，安装 Python 依赖 (flask pillow)..."
        "$PY" -m pip install --no-cache-dir --target "$ROOT/site-packages" flask pillow \\
          || { echo "依赖安装失败，请检查网络后重试 toolbox"; exit 1; }
      fi
      echo "Toolbox 启动中 → http://localhost:${PORT}"
      nohup "$PY" "$ROOT/home/server.py" >"$LOG_FILE" 2>&1 &
      echo $! > "$PID_FILE"
      echo "PID: $(cat "$PID_FILE") | 日志: $LOG_FILE | 停止: toolbox stop"
      for i in $(seq 1 60); do
        curl -sf "http://127.0.0.1:${PORT}/" >/dev/null 2>&1 && \\
          { open "http://localhost:${PORT}/" 2>/dev/null || true; } && break
        sleep 0.5
      done
    EOS
    chmod 0755, bin/"toolbox"
  end

  def caveats
    port = ENV["TOOLBOX_PORT"] || "9053"
    <<~EOS
      Toolbox 已安装！

        运行:  toolbox          (后台启动, 关闭终端不影响)
        停止:  toolbox stop
        状态:  toolbox status
        访问:  http://localhost:#{port}

      首次运行会自动安装 Python 依赖 (flask/pillow)，需网络。
      端口 #{port} (安装时可用 TOOLBOX_PORT=xxxx brew install toolbox 自定义)

      依赖说明:
        - pandoc 已自动安装 (doc-convert / epub-convert 必需)
        - git 推送功能需 git (macOS 自带 Xcode CLT)
        - LaTeX (PDF 转换, 可选): brew install --cask mactex-no-gui
    EOS
  end

  test do
    assert_predicate bin/"toolbox", :exist?
  end
end
