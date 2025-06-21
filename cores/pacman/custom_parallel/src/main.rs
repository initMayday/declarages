/*
*   REMEMBER TO DO "cargo build --release" TO UPDATE THE BINARY FOR THE PACMAN CORE TO EXECUTE
*/
use std::{env, process::Command, thread::{self, JoinHandle}, time::Instant};

fn main() {
    // Parallel checking for updates
    let args: Vec<String> = env::args().collect();
    let current_directory = &args[1];
    let _res = env::set_current_dir(current_directory);
    let output = Command::new("ls").output().expect("Failed to exec command");
    let custom_packages = String::from_utf8(output.stdout).unwrap();
    let custom_packages_vec: Vec<String> = custom_packages.split('\n').map(|x| x.to_string()).filter(|x| x != "").collect();
    let mut handles: Vec<JoinHandle<String>> = vec![];
    let mut updated_packages: Vec<String> = Vec::new();
    print!("\x1b[1m");

    for package in custom_packages_vec {
        let handle = thread::spawn(move || {
            let start = Instant::now();
            //println!("[LOG] Checking for Updates: {}", package);
            let mut current_version = String::from_utf8(Command::new("bash").arg("-c").arg("cd ".to_owned() + &package + "&& makepkg --printsrcinfo | awk -F ' = ' '/pkgver/ {print $2}'").output().expect("failedtoexec").stdout).unwrap();
            Command::new("bash").arg("-c").arg("cd ".to_owned() + &package + "&& git reset --hard && git pull").output().expect("failedtoexec");
            Command::new("bash").arg("-c").arg("cd ".to_owned() + &package + "&& makepkg -o").output().expect("failedtoexec");
            let mut new_version = String::from_utf8(Command::new("bash").arg("-c").arg("cd ".to_owned() + &package + "&& makepkg --printsrcinfo | awk -F ' = ' '/pkgver/ {print $2}'").output().expect("failedtoexec").stdout).unwrap();
            current_version.pop(); new_version.pop(); // Removes trailing /n

            if current_version != new_version {
                println!("\x1b[33m[LOG] Needs Update: {} (Old: {:?}, New: {:?})\x1b[0m\x1b[1m", package, current_version, new_version);
                return package;
            } else {
                println!("[LOG] Already Up to Date: {} ({}ms)", package, start.elapsed().as_millis());
                return "".to_string();
            }
        });
        handles.push(handle);
    }
    
    for handle in handles {
        let package = handle.join();
        match package {
            Ok(package) => {
                if package != "".to_string() {
                    updated_packages.push(package);
                }
            },
            Err(_) => (),
        }
    }

    for package in updated_packages {
        println!("[LOG] Updating: {}", package);
        Command::new("bash").arg("-c").arg("cd ".to_owned() + &package + "&& makepkg -si --noconfirm").spawn().expect("Unable to output command").wait().expect("Failed to wait for output");
        println!("[LOG] Completed: {}", package);
    }

    print!("\x1b[0m");
}
