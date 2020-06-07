<?php

require 'includes/functions.php';
require 'includes/repo-index.php';

$table_output = '';
foreach ($index as $category => $packages) {
    foreach ($packages as $package => $versions) {
        $package_info = json_decode(file_get_contents('./repo/'.$category.'/'.$package.'/package.info'), 1);
        $version = scandir('./repo/'.$category.'/'.$package);
        $version = $version[count($version)-2];
        $table_output .= "
            <tr>
                <td>{$package_info['codename']}</td>
                <td>{$package_info['name']} - {$package_info['description']}</td>
                <td>{$version}</td>
                <td>{$category}</td>
            </tr>
        ";
    }
}

?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <title>Mercury - Halo CE Package Manager</title>
    <link rel="icon" type="image/png" href="assets/img/logo.png">
    <link rel="stylesheet" type="text/css" href="assets/css/material-icons.css">
    <link rel="stylesheet" type="text/css" href="assets/css/roboto-font.css">
    <link rel="stylesheet" type="text/css" href="assets/css/main.css">
</head>
<body>
    <header>
        <nav>
            <div class="nav-logo">
                <img src="assets/img/logo.png" draggable="false" alt="mercury logo">
                Mercury
            </div>
            <ul>
                <li>
                    <a href="#downloads">
                        <i class="material-icons">file_download</i>
                        <div>Downloads</div>
                    </a>
                </li>
                <li>
                    <a href="https://github.com/Sledmine/Mercury" target="_blank">
                        <i class="material-icons">code</i>
                        <div>Github</div>
                    </a>
                </li>
            </ul>
        </nav>
    </header>
    <div class="wrapper">
        <div class="logo">
            <img src="assets/img/logo.png" draggable="false" alt="mercury logo">
            <h1>Mercury v1.1</h1>
            <p>Developed by Sledmine & JerryBrick</p>
        </div>
        <div class="card">
            <div class="card-header">
                <h2>Recent Changes:</h2>
            </div>
            <div class="card-body">
                <h4>[1.1]</h4>
                <ul>
                    <li>- Binaries released for Windows-x32.</li>
                    <li>- Fixed issue getting game routes.</li>
                </ul>
                <br>
                <h4>[1.0]</h4>
                <ul>
                    <li>- Initial launch of Mercury-x64.</li>
                </ul>
            </div>
        </div>
        <div class="card">
            <div class="card-header">
                <h2>What is mercury?</h2>
            </div>
            <div class="card-body">
                <div id="downloads" class="flag"></div>
                <p>It is a package manager for Halo Custom Edition, a package can be your favorite "graphic" mod, a new map for your game, etc.</p>
            </div>
        </div>
        <div class="card">
            <div class="card-header">
                <h2>How do I install it?</h2>
            </div>
            <div class="card-body">
                <p>1.- Download the Mercury version for your operating system:</p>
                <div class="download-links">
                    <a href="./downloads/release/Mercury1.1-x64.zip" class="btn" target="_blank">Mercury 1.1 Windows-x64</a>
                    <a href="./downloads/release/Mercury1.1-x32.zip" class="btn" target="_blank">Mercury 1.1 Windows-x32</a>
                </div>
                <p>2.- Unzip the file in any folder (preferably "My Documents").</p>
                <p>3.- Enter the previously unzipped folder called "Mercury1.1-x32" or "Mercury1.1-x64".</p>
                <p>4.- Open a command line with administrator permissions in that folder.</p>
            </div>
        </div>
        <div class="card">
            <div class="card-header">
                <h2>How is it used?</h2>
            </div>
            <div class="card-body">
                <p>After opening the command line as administrator you can use the following commands:</p>
                <br>
                <p>
                    <b>mercury install "paquete"</b>
                    <br>With this command you can install packages in your game.
                    <br><i>Example: mercury install hac2</i>
                </p>
                <br>
                <p>
                    <b>mercury remove "paquete"</b>
                    <br>Uninstall previously installed packages.
                    <br><i>Example: mercury remove hac2</i>
                </p>
                <br>
                <p>
                    <b>mercury list "paquete"</b>
                    <br>List information about the packages installed in the game.
                    <br><i>Example: mercury list all</i>
                </p>
                <br>
                <p>
                    <b>mercury version</b>
                    <br>Throw in the console the version and the license of Mercury.
                </p>
                <br>
                <p>
                    <b>For more information about all commands type "mercury" in the console.</b>
                </p>
            </div>
        </div>
        <div class="card">
            <div class="card-header">
                <h2>How do I download Flood 09?</h2>
            </div>
            <div class="card-body">
                <p>
                    Simply type the command:
                    <br><b>mercury install f09</b>
                    <br><br>Text will start to appear on the console and you should see this:
                </p>
                <br>
                <img src="assets/img/f09.png" class="rounded mx-auto d-block" alt="flood 09 successfull installation screenshot" />
                <br><br>
                <p>If everything went well you should be able to join a Flood 09 beta server.</p>
            </div>
        </div>
        <div class="packages-table">
            <h4>List of packages available in Mercury</h4>
            <table class="table table-light">
                <thead class="thead-dark">
                    <tr>
                        <th>Package</th>
                        <th>Full name and description</th>
                        <th>Latest version</th>
                        <th>Category</th>
                    </tr>
                </thead>
                <tbody>
                    <?php print($table_output) ?>
                </tbody>
            </table>
        </div>
    </div>
    <footer>
        <h4>Mercury: Halo CE Packages Manager</h4>
        <p>Developed by Sledmine & JerryBrick</p>
    </footer>
</body>
</html>