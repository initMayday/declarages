/*
*   REMEMBER TO DO "cargo build --release" TO UPDATE THE BINARY FOR THE PACMAN CORE TO EXECUTE
*/

use std::{env, process::Command, thread::{self, JoinHandle}, time::Instant};
use indicatif::{MultiProgress, ProgressBar, ProgressStyle};

fn main() {

    // Get arguments passed
    let args: Vec<String> = env::args().collect();

    // Get what directory the packages are in
    let current_directory = &args[1];
    let _res = env::set_current_dir(current_directory);

    // Get the packages in that directory
    let output = Command::new("ls").output().expect("Failed to exec command");
    let custom_packages = String::from_utf8(output.stdout).unwrap();
    let custom_packages_vec: Vec<String> = custom_packages.split('\n').map(|x| x.to_string()).filter(|x| x != "").collect();
    let mut updated_packages: Vec<String> = Vec::new();
    
    // Create Threads
    let mut handles: Vec<JoinHandle<Option<String>>> = vec![];

    // Create progress bars
    let multi_progress = MultiProgress::new();
    let style = ProgressStyle::with_template("{msg} [{elapsed_precise}]").unwrap();
    let mut progress_bars = vec![];
    for _package in &custom_packages_vec {
        let pb = multi_progress.add(ProgressBar::new(200));
        pb.set_style(style.clone());
        pb.enable_steady_tick(std::time::Duration::new(1, 0));
        progress_bars.push(pb);
    }

    // Check for updates
    for (i, package) in custom_packages_vec.into_iter().enumerate() {
        let pb = progress_bars[i].clone();
        let handle = thread::spawn(move || {
            let start = Instant::now();
            pb.set_message(format!("[LOG] Getting Version: {} [{:?}ms]", package, start.elapsed().as_millis()));

            let mut current_version = String::from_utf8(Command::new("bash").arg("-c").arg("cd ".to_owned() + &package + "&& makepkg --printsrcinfo | awk -F ' = ' '/pkgver/ {print $2}'").output().expect("failedtoexec").stdout).unwrap();

            pb.set_message(format!("[LOG] Pulling: {} [{:?}ms]", package, start.elapsed().as_millis()));
            Command::new("bash").arg("-c").arg("cd ".to_owned() + &package + "&& git reset --hard && git pull").output().expect("failedtoexec");
            pb.set_message(format!("[LOG] Applying Pull: {} [{:?}ms]", package, start.elapsed().as_millis()));
            let out = Command::new("bash").arg("-c").arg("cd ".to_owned() + &package + "&& makepkg -o").output().expect("failedtoexec");
            if !out.status.success() {
                pb.finish_with_message(format!("[ERROR] Failed to makepkg, perhaps some make dependencies are missing? If so, explicitly list them in official packages: {} [{:?}ms], Error: {}", package, start.elapsed().as_millis(), String::from_utf8_lossy(&out.stderr)));
                return None;
            }
            pb.set_message(format!("[LOG] Getting New Version: {} [{:?}ms]", package, start.elapsed().as_millis()));
            let mut new_version = String::from_utf8(Command::new("bash").arg("-c").arg("cd ".to_owned() + &package + "&& makepkg --printsrcinfo | awk -F ' = ' '/pkgver/ {print $2}'").output().expect("failedtoexec").stdout).unwrap();

            current_version.pop(); new_version.pop(); // Removes trailing /n

            if current_version != new_version {
                pb.finish_with_message(format!("[LOG] Needs Update: {} [{:?}ms], Old: {}, New: {}", package, start.elapsed().as_millis(), current_version, new_version));
                return Some(package);
            } else {
                pb.finish_with_message(format!("[LOG] Already Up to Date: {} [{}] [{:?}ms]", package, new_version, start.elapsed().as_millis()));
                return None;
            }
        });
        handles.push(handle);
    }
    
    // Check if any package failed the update check
    for handle in handles {
        let package = handle.join(); // Join wraps it in a result, to see if the thread panicked
        match package {
            Ok(package) => {    
                if package.is_some() {
                    updated_packages.push(package.unwrap());
                }
            }
            Err(_error) => { println!("[ERROR] Thread Panicked!"); } 
        }
    }

    // Update packages which failed the check
    for package in updated_packages {
        println!("[LOG] Updating: {}", package);
        Command::new("bash").arg("-c").arg("cd ".to_owned() + &package + "&& makepkg -si --noconfirm").spawn().expect("Unable to output command").wait().expect("Failed to wait for output");
        println!("[LOG] Completed: {}", package);
    }
}
