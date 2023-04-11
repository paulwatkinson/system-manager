pub mod activate;
pub mod generate;
mod systemd;

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::os::unix;
use std::path::{Path, PathBuf};
use std::{fs, str};

pub const FLAKE_ATTR: &str = "systemConfigs";
pub const PROFILE_DIR: &str = "/nix/var/nix/profiles/system-manager-profiles";
pub const PROFILE_NAME: &str = "system-manager";
pub const GCROOT_PATH: &str = "/nix/var/nix/gcroots/system-manager-current";
pub const SYSTEM_MANAGER_STATE_DIR: &str = "/var/lib/system-manager/state";
pub const STATE_FILE_NAME: &str = "system-manager-state.json";
pub const SYSTEM_MANAGER_STATIC_NAME: &str = ".system-manager-static";

#[derive(PartialEq, Debug, Clone, Serialize, Deserialize)]
#[serde(from = "String", into = "String", rename_all = "camelCase")]
pub struct StorePath {
    pub store_path: PathBuf,
}

impl From<String> for StorePath {
    fn from(path: String) -> Self {
        // TODO: handle this better
        if !path.starts_with("/nix/store/") {
            panic!("Error constructing store path, not in store: {path}");
        }
        StorePath {
            store_path: PathBuf::from(path),
        }
    }
}

impl From<StorePath> for PathBuf {
    fn from(value: StorePath) -> Self {
        value.store_path
    }
}

impl From<StorePath> for String {
    fn from(value: StorePath) -> Self {
        format!("{}", value.store_path.display())
    }
}

impl std::fmt::Display for StorePath {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.store_path.display())
    }
}

fn create_store_link(store_path: &StorePath, from: &Path) -> Result<()> {
    create_link(Path::new(&store_path.store_path), from)
}

fn create_link(to: &Path, from: &Path) -> Result<()> {
    log::info!("Creating symlink: {} -> {}", from.display(), to.display());
    if from.exists() {
        if from.is_symlink() {
            fs::remove_file(from)?;
        } else {
            anyhow::bail!("File exists and is no link!");
        }
    }
    unix::fs::symlink(to, from)?;
    Ok(())
}

fn remove_link(from: &Path) -> Result<()> {
    log::info!("Removing symlink: {}", from.display());
    if from.is_symlink() {
        fs::remove_file(from)?;
        Ok(())
    } else {
        anyhow::bail!("Not a symlink!");
    }
}

fn remove_file(from: &Path) -> Result<()> {
    log::info!("Removing file: {}", from.display());
    fs::remove_file(from)?;
    Ok(())
}

fn remove_dir(from: &Path) -> Result<()> {
    log::info!("Removing directory: {}", from.display());
    fs::remove_dir(from)?;
    Ok(())
}

pub fn etc_dir(ephemeral: bool) -> PathBuf {
    if ephemeral {
        Path::new("/run").join("etc")
    } else {
        PathBuf::from("/etc")
    }
}
