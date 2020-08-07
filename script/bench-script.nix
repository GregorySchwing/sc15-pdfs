{ pkgs   ? import <nixpkgs> {},
  stdenv ? pkgs.stdenv,
  makeWrapper ? pkgs.makeWrapper,
  hwloc ? pkgs.hwloc,
  ipget ? pkgs.ipget,
  sources ? import ./local-sources.nix,
  buildDunePackage ? pkgs.ocamlPackages.buildDunePackage,
  pbenchOcaml ? import sources.pbenchOcamlSrcs.pbenchOcaml { pbenchOcamlSrc = sources.pbenchOcamlSrcs.pbenchOcamlSrc; }
}:

let benchDune =
      buildDunePackage rec {
        pname = "graph";
        version = "1.0";
        src = sources.benchOcamlSrc;
        buildInputs = [ pbenchOcaml ];
      };
in

let bench = import sources.pbenchOcamlSrcs.pbenchCustom {
                      benchSrc = sources.benchOcamlSrc;
                      bench = "${benchDune}/bin/graph"; };
in

stdenv.mkDerivation rec {
  name = "bench-script";

  src = "${sources.nixSrc}/dummy";

  buildInputs = [ makeWrapper ];

  configurePhase =
    let getNbCoresScript = pkgs.writeScript "get-nb-cores.sh" ''
      #!/usr/bin/env bash
      nb_cores=$( ${hwloc}/bin/hwloc-ls --only core | wc -l )
      echo $nb_cores
    '';
    in
    ''
    cp ${getNbCoresScript} get-nb-cores.sh
    '';

  installPhase = ''
    mkdir -p $out
    cp get-nb-cores.sh $out/
    cp ${bench}/bench $out/graph
    wrapProgram $out/graph \
      --prefix PATH ":" $out/ \
      --prefix PATH ":" ${ipget}/bin
    '';


}
