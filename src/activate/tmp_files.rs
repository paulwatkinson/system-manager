use crate::activate;
use crate::activate::etc_files::FileTree;

use super::ActivationResult;
use std::path::PathBuf;
use std::str::FromStr;
use std::{fs, process};

type TmpFilesActivationResult = ActivationResult<()>;

pub fn activate(etc_tree: &FileTree) -> TmpFilesActivationResult {
    let conf_files = etc_tree
        .nested
        .get("etc")
        .and_then(|etc| etc.nested.get("tmpfiles.d"))
        .map_or(vec![], |tmpfiles_d| {
            tmpfiles_d
                .nested
                .iter()
                .map(|(_, node)| node.path.to_string_lossy().to_string())
                .collect::<Vec<_>>()
        });

    for value in ["/lib", "/lib64"] {
        let target = PathBuf::from_str(value).unwrap();

        if target.is_symlink() {
            fs::remove_file(&target).unwrap();
        }
    }

    let mut cmd = process::Command::new("systemd-tmpfiles");
    cmd.arg("--create").arg("--remove").args(conf_files);
    log::debug!("running {:#?}", cmd);
    let output = cmd
        .stdout(process::Stdio::inherit())
        .stderr(process::Stdio::inherit())
        .output()
        .expect("Error forking process");

    output.status.success().then_some(()).ok_or_else(|| {
        activate::ActivationError::WithPartialResult {
            result: (),
            source: anyhow::anyhow!(
                "Error while creating tmpfiles\nstdout: {}\nstderr: {}",
                String::from_utf8_lossy(output.stdout.as_ref()),
                String::from_utf8_lossy(output.stderr.as_ref())
            ),
        }
    })
}
