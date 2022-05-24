{ lib
, python3
, python3Packages
, fetchFromGitHub
}:

with python3Packages;

let
  apscheduler = (
    let apscheduler_module = (
      buildPythonPackage rec {
        pname = "APScheduler";
        version = "3.9.1";
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-ZeZXS2OVSY03HQRfKop+T31Qxq0h73MT0VscfPIN8eM=";
        };
        doCheck = false;
        nativeBuildInputs = [
          setuptools_scm
          pytz
          tzlocal
          six
        ];
      }
    );
    in python3.withPackages (ps: [apscheduler_module ])
 );
in

buildPythonApplication rec {
  pname = "zfs_uploader";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "ddebeau";
    repo = pname;
    rev = "c48c1fa8368577d7c4e9f9c4a4e306cdfdc08944";
    hash = "sha256-sx3Hj/H41KOZSWisbbdSYbSGzj9R00236gyUjvoh3UY=";
  };

  doCheck = false;

  propagatedBuildInputs = with python3Packages; [
    apscheduler
    click
    boto3
    pytz
    tzlocal
    six
    setuptools
  ];

  preBuild = ''
    cat >setup.py <<'EOF'
    from setuptools import setup
    setup(
      name="zfs_uploader",
      version="0.8.0",
      author="David Debeau",
      author_email="ddebeau@gmail.com",
      description="ZFS snapshot to S3 uploader.",
      url="https://github.com/ddebeau/zfs_uploader",
      packages=['zfs_uploader'],
      entry_points = {
        'console_scripts': ['zfsup=zfs_uploader.__main__:cli'],
      },
      install_requires=['apscheduler', 'boto3', 'click'],
    )
    EOF
  '';

  meta = with lib; {
    homepage = "https://github.com/ddebeau/zfs_uploader";
    description = "Simple program for backing up full and incremental ZFS snapshots to Amazon S3.";
    longDescription = ''
      ZFS Uploader is a simple program for backing up full and incremental ZFS
      snapshots to Amazon S3. It supports CRON based scheduling and can
      automatically remove old snapshots and backups. A helpful CLI (zfsup)
      lets you run jobs, restore, and list backups.
    '';
    license = licenses.mit;
  };
}
