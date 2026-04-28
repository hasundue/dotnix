final: prev: {
  python3 = prev.python3.override {
    packageOverrides = pyfinal: pyprev: {
      aioboto3 = pyprev.aioboto3.overridePythonAttrs (_: {
        doCheck = false;
      });
    };
  };
  python3Packages = final.python3.pkgs;
}
