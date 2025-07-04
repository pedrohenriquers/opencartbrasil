<?php
class ControllerStartupSass extends Controller {
	public function index() {
		$file = DIR_APPLICATION . 'view/stylesheet/bootstrap.css';

		// COMENTE TODO ESTE BLOCO PARA DESABILITAR A COMPILAÇÃO DO BOOTSTRAP.SCSS
		/*
		if (!is_file($file) || !$this->config->get('developer_sass')) {
			$scss = new \Leafo\ScssPhp\Compiler();
			$scss->setImportPaths(DIR_APPLICATION . 'view/stylesheet/sass/');

			$output = $scss->compile('@import "_bootstrap.scss"');

			$handle = fopen($file, 'w');

			flock($handle, LOCK_EX);

			fwrite($handle, $output);

			fflush($handle);

			flock($handle, LOCK_UN);

			fclose($handle);
		}
		*/
	}
}