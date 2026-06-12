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
    rev = "a803e59a56eb88f6240bc208b6de8c13c5da6d5b";
    hash = "sha256-7hr7S72Fcvzq5D9htuawE3YYY1spCkVyP/5zftCXTJQ=";
  };

  meta = {
    description = "Tree-sitter grammar for the Plan 9 rc shell";
    homepage = "https://github.com/chiefnoah/tree-sitter-rcsh";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
  };
}
