{
  fetchFromGitHub,
  lib,
  tree-sitter,
}:

tree-sitter.buildGrammar {
  language = "mk";
  version = "0.1.1";
  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "tree-sitter-mk";
    rev = "v0.1.1";
    hash = "sha256-psDtbRyi21cTpBNJtim1dGylc5s7VdZJh2FDbsZ+2r4=";
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
