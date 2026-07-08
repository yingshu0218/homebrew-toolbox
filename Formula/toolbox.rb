class Toolbox < Formula
  desc "个人工具箱集合 — 文档转换/EPUB/网络检测 (Flask 多工具整合)"
  homepage "https://github.com/yingshu0218/toolbox"
  url "https://github.com/yingshu0218/toolbox/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "d06c144036b8c901a8b51ffea8bf563ec657d20954fdbef5aa811b379e3daec4"
  version "1.0.0"
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
      export PYTHONPATH="$ROOT/site-packages"
      if ! "$PY" -c "import flask" 2>/dev/null; then
        echo "首次运行，安装 Python 依赖 (flask pillow)..."
        "$PY" -m pip install --no-cache-dir --target "$ROOT/site-packages" flask pillow \\
          || { echo "依赖安装失败，请检查网络后重试 toolbox"; exit 1; }
        echo "依赖安装完成"
      fi
      echo "Toolbox 启动中 → http://localhost:${PORT}"
      "$PY" "$ROOT/home/server.py" &
      PID=$!
      for i in $(seq 1 60); do
        curl -sf "http://127.0.0.1:${PORT}/" >/dev/null 2>&1 && \\
          { open "http://localhost:${PORT}/" 2>/dev/null || true; } && break
        sleep 0.5
      done
      trap 'kill $PID 2>/dev/null' EXIT INT TERM
      wait $PID
    EOS
    chmod 0755, bin/"toolbox"
  end

  def caveats
    port = ENV["TOOLBOX_PORT"] || "9053"
    <<~EOS
      Toolbox 已安装！

        运行:  toolbox
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
