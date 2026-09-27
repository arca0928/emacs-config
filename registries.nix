inputs: [
  {
    name = "gnu";
    type = "elpa";
    path = inputs.elpa.outPath + "/elpa-packages";
    auto-sync-only = true;
  }
  {
    name = "melpa";
    type = "melpa";
    path = inputs.melpa.outPath + "/recipes";
  }
  {
    type = "elpa";
    path = inputs.nongnu.outPath + "/elpa-packages";
  }
  {
    name = "emacsmirror";
    type = "gitmodules";
    path = inputs.epkgs.outPath + "/.gitmodules";
  }
]
