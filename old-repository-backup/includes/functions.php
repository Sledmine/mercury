<?php 

function getDirIndex($path) {
	$dir = scandir($path);
	for ($i=0; $i < count($dir)-2; $i++) { 
		$dir[$i] = $dir[$i+2];
	}
	unset($dir[count($dir)-1]);
	unset($dir[count($dir)-1]);
	return $dir;
}

?>