<?php 


if (isset($_GET['pkg'])) {
	$repoIndex = file_get_contents('index.json');
	$repoIndex = json_decode($repoIndex, true);
	$buffer = explode('-', $_GET['pkg']);
	$packageName = $buffer[0];
	$packageVersion = (isset($buffer[1])) ? $buffer[1] : null;

	if (isset($repoIndex[$packageName])) {
		if (isset($packageVersion)) {
			$path = $repoIndex[$packageName]['category'].'/'.$packageName.'/'.$packageVersion.'/';
			if (is_dir($path)) {
				$output['version'] = $packageVersion;
				$output['paths'] = getLinks($path);
				echo(str_replace('\\', '', json_encode($output)));
			}
		}
		else {
			$path = $repoIndex[$packageName]['category'].'/'.$packageName.'/';
			$versionList = scandir($path);
			$lastVersion = $versionList[count($versionList)-1];
			$path .= $lastVersion.'/';
			$output['version'] = $lastVersion;
			$output['paths'] = getLinks($path);
			echo(str_replace('\\', '', json_encode($output)));
		}	
	}
}

function getLinks($path) {
	$dir = scandir($path);
	$dir[0] = null;
	$dir[1] = null;
	for ($i=0; $i < count($dir)-2; $i++) { 
		$resourcesPaths[$i] = $path.$dir[$i+2];
	}
	return $resourcesPaths;
}

?>