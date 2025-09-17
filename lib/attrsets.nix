{ nixpkgs, ... }:
let
  inherit (builtins)
    attrNames
    concatMap
    foldl'
    head
    isAttrs
    length
    listToAttrs
    tail
    ;

  inherit (nixpkgs.lib) recursiveUpdateUntil splitString;
in rec {
  isTypedAttrs = attrs:
    attrs ? type || attrs ? _type;

  isUntypedAttrs = attrs:
    isAttrs attrs && !isTypedAttrs attrs;

  recursiveUpdateUntilTypedAttrs = lhs: rhs:
    let stop_cond = e: isAttrs e -> isTypedAttrs e;
    in
      recursiveUpdateUntil (_: lhs: rhs: stop_cond lhs || stop_cond rhs) lhs rhs;

  initAttrPath = attrPath: value:
    if length attrPath > 1
    then { ${head attrPath} = initAttrPath (tail attrPath) value; }
    else if length attrPath > 0
    then { ${head attrPath} = value; }
    else {};

  attrsToTree = attrsToTreeCond (_: true);

  attrsToTreeCond = cond: sep: attrs:
    let stop_cond = e: isAttrs e -> !cond e;
    in
      foldl' (recursiveUpdateUntil (_: lhs: rhs: stop_cond lhs || stop_cond rhs)) {} (
        map (name:
          let value = attrs.${name};
          in initAttrPath (splitString sep name) (
            if !stop_cond value
            then attrsToTreeCond cond sep value
            else value
          )
        ) (attrNames attrs)
      );

  filterAttrsRecursive = filterAttrsRecursiveCond (_: true);

  filterAttrsRecursiveCond = cond: pred: attrs:
    let recurse = attrPath: attrs:
      listToAttrs (
        concatMap (name:
          let
            attrPath' = attrPath ++ [ name ];
            value = attrs.${name};
          in
            if isAttrs value && cond value
            then [ { inherit name; value = recurse attrPath' value; } ]
            else if pred attrPath' value
            then [ { inherit name value; } ]
            else []
        ) (attrNames attrs)
      );
    in
      recurse [] attrs;
}
