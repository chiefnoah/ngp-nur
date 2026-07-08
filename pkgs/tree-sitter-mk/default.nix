{
  fetchFromGitHub,
  lib,
  tree-sitter,
}:

tree-sitter.buildGrammar {
  language = "mk";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "tree-sitter-mk";
    rev = "2965e2dbf74f7dd3fe847c65c92124b1ccc4e5f5";
    hash = "sha256-N1vjwokTnAhXHiBJ89P3CIqHCXeXz1rzGFnT0g54sLk=";
  };

  meta = {
    description = "Tree-sitter grammar for Plan 9 mk files";
    homepage = "https://github.com/chiefnoah/tree-sitter-mk";
    license = lib.licenses.mit;
    maintainers = [
      {
        email = "noah@packetlost.dev";
        github = "chiefnoah";
        githubId = 3588683;
        name = "Noah Pederson";
      }
    ];
  };
}
