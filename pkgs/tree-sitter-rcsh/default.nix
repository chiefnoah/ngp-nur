{
  fetchFromGitHub,
  lib,
  tree-sitter,
}:

tree-sitter.buildGrammar {
  language = "rcsh";
  version = "0.0.1";
  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "tree-sitter-rcsh";
    rev = "cff832d7d7a72b7fa186f6a6f531ab21908ba5ce";
    hash = "sha256-d1FCNpP1mJHbWa20an91JbRW7MIXdX3D0bCJhT3wLVc=";
  };

  meta = {
    description = "Tree-sitter grammar for the Plan 9 rc shell";
    homepage = "https://github.com/chiefnoah/tree-sitter-rcsh";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
  };
}
