{
  description = "THIS IS AN AUTO-GENERATED FILE. PLEASE DON'T EDIT IT MANUALLY.";
  inputs = {
    compat = {
      flake = false;
      owner = "emacs-compat";
      repo = "compat";
      type = "github";
    };
    consult = {
      flake = false;
      owner = "minad";
      repo = "consult";
      type = "github";
    };
    corfu = {
      flake = false;
      owner = "minad";
      repo = "corfu";
      type = "github";
    };
    ef-themes = {
      flake = false;
      owner = "protesilaos";
      repo = "ef-themes";
      type = "github";
    };
    modus-themes = {
      flake = false;
      owner = "protesilaos";
      repo = "modus-themes";
      type = "github";
    };
    orderless = {
      flake = false;
      owner = "oantolin";
      repo = "orderless";
      type = "github";
    };
    setup = {
      flake = false;
      type = "git";
      url = "https://codeberg.org/pkal/setup.el";
    };
    vertico = {
      flake = false;
      owner = "minad";
      repo = "vertico";
      type = "github";
    };
  };
  outputs = _: { };
}
