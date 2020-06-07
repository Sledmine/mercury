<?php 

include 'includes/functions.php';
include 'includes/repo-index.php';

if (isset($_GET['package'])) {
	foreach ($index as $category => $packages) {
		if (file_exists('./repo/'.$category.'/'.$_GET['package'])) {
			$package = [];
			foreach ($packages as $key => $versions) {
				if ($key == $_GET['package']) {
					$package['category'] = $category;
				}
			}
			$package['name'] = $_GET['package'];
			if (isset($_GET['version'])) $package['version'] = $_GET['version'];
			else {
				$package['version'] = getDirIndex('./repo/'.$package['category'].'/'.$package['name']);
				$package['version'] = $package['version'][count($package['version'])-2];
			}
			$package['paths'] = ['mercury.shadowmods.net/repo/'.implode('/', $package).'/'.$package['name'].'.merc'];
			print(str_replace('\\', '', json_encode($package)));
			break;
		}
	}
} else {
	print(json_encode($index));
}

?>