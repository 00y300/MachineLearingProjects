{
  description = "PyTorch development environment with data science packages";
  nixConfig = {
    extra-substituters = [
      "https://cache.flox.dev"
      "https://cuda-maintainers.cachix.org"
      "https://cache.nixos-cuda.org"
    ];
    extra-trusted-public-keys = [
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = builtins.elem system [
              "x86_64-linux"
              "aarch64-linux"
            ];
          };
        };
        python = pkgs.python313;
        pythonPackages = python.pkgs;

        vscode-with-extensions = pkgs.vscode-with-extensions.override {
          vscodeExtensions =
            with pkgs.vscode-extensions;
            [
              # Python extensions
              ms-python.python
              ms-python.vscode-pylance
              ms-toolsai.jupyter
              ms-toolsai.jupyter-keymap
              ms-toolsai.jupyter-renderers
              ms-toolsai.vscode-jupyter-cell-tags
              ms-toolsai.vscode-jupyter-slideshow
              # Vim extension
              vscodevim.vim
              # VSCode Icons extension
              vscode-icons-team.vscode-icons
            ]
            ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
              {
                name = "quarto";
                publisher = "quarto";
                version = "1.130.0";
                sha256 = "sha256-3jbQ2IemKCSD4mzNA5zxAn5pYxglJ51fyM/1kMEfApM=";
              }
            ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            python
            vscode-with-extensions
          ]
          ++ (with pkgs; [
            sqlite
            sqlit-tui
            quarto
          ])
          ++ (with pythonPackages; [
            # Core Python tools
            pip
            pynvim
            debugpy
            pyyaml

            # PyTorch packages
            torchmetrics
            torch

            # Jupyter and notebook tools
            jupyter-client
            jupyterlab
            notebook
            nbformat
            ipykernel
            ipywidgets
            jupytext

            # Data science packages
            numpy
            xgboost
            pandas
            seaborn
            matplotlib
            scikit-learn
            statsmodels

            # Visualization
            cairosvg
            plotly
            kaleido
            graphviz

            # Utilities
            pyperclip
            greenlet
          ]);
          shellHook = ''
            ${
              if pkgs.stdenv.isLinux then
                ''
                  export CUDA_PATH=${pkgs.cudaPackages_13_0.cudatoolkit}
                  export LD_LIBRARY_PATH=${pkgs.cudaPackages_13_0.cudatoolkit}/lib:${pkgs.cudaPackages_13_0.cudnn}/lib:${
                    pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]
                  }:$LD_LIBRARY_PATH
                  export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
                  export EXTRA_CCFLAGS="-I/usr/include"
                ''
              else
                ""
            }
            # Create and activate venv
            VENV=.venv
            if test ! -d $VENV; then
              ${python}/bin/python -m venv $VENV
            fi
            source ./$VENV/bin/activate
            # Install requirements if the file exists
            if test -f requirements.txt; then
              pip install -r requirements.txt
            else
              echo "Warning: requirements.txt not found, skipping pip install"
            fi
          '';
        };
      }
    );
}
