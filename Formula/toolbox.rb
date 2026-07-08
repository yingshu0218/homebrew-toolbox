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
    libexec.install Dir["*"]
    venv = virtualenv_create(libexec/"venv", Formula["python@3.12"].opt_bin/"python3")
    venv.pip_install "flask"
    venv.pip_install "pillow"
    (bin/"toolbox").write_env_script libexec/"bin/toolbox", {
      TOOLBOX_PYTHON: "#{libexec}/venv/bin/python3",
      TOOLBOX_ROOT:   libexec.to_s,
    }
  end

  def caveats
    <<~EOS
      Toolbox 已安装！

        运行:  toolbox
        访问:  http://localhost:5001

      依赖说明:
        - pandoc 已自动安装 (doc-convert / epub-convert 必需)
        - git 推送功能需 git (macOS 自带 Xcode CLT)
        - LaTeX (PDF 转换, 可选): brew install --cask mactex-no-gui
    EOS
  end

  test do
    assert_predicate bin/"toolbox", :exist?
    assert_match "Flask", shell_output("#{libexec}/venv/bin/python3 -c 'import flask; print(flask.__name__)'")
  end
end
