<?php
class ControllerStartupSass extends Controller {
	public function index() {
		$file = DIR_APPLICATION . 'view/theme/' . $this->config->get('theme_directory') . '/stylesheet/bootstrap.css';

		// COMENTE TODO ESTE BLOCO PARA DESABILITAR A COMPILAÇÃO DO BOOTSTRAP.SCSS
		/*
		if (!is_file($file) || (is_file(DIR_APPLICATION . 'view/theme/' . $this->config->get('theme_directory') . '/stylesheet/sass/bootstrap.scss') && !$this->config->get('developer_sass'))) {
			$scss = new \Leafo\ScssPhp\Compiler();
			$scss->setImportPaths(DIR_APPLICATION . 'view/theme/' . $this->config->get('theme_directory') . '/stylesheet/sass/');

			$output = $scss->compile('@import "bootstrap.scss"');

			// Drop the closing bracket to newline
			$handle = fopen($file, 'w');

			flock($handle, LOCK_EX);

			fwrite($handle, $output);

			fflush($handle);

			flock($handle, LOCK_UN);

			fclose($handle);
		}
		*/

		$file = DIR_APPLICATION . 'view/theme/' . $this->config->get('theme_directory') . '/stylesheet/stylesheet.css';

		// COMENTE TODO ESTE SEGUNDO BLOCO PARA DESABILITAR A COMPILAÇÃO DO _STYLESHEET.SCSS
		/*
		if (!is_file($file) || (is_file(DIR_APPLICATION . 'view/theme/' . $this->config->get('theme_directory') . '/stylesheet/_stylesheet.scss') && !$this->config->get('developer_sass'))) {
			include_once(DIR_STORAGE . 'vendor/leafo/scssphp/scss.inc.php'); // Esta linha também será comentada

			$scss = new \Leafo\ScssPhp\Compiler();
			$scss->setImportPaths(DIR_APPLICATION . 'view/theme/' . $this->config->get('theme_directory') . '/stylesheet/');

			$output = $scss->compile('@import "_stylesheet.scss"');

			$output = preg_replace('/\s*{\s*/', ' {' . "\n" . '    ', $output);
			$output = preg_replace('/;\s*/', ';' . "\n" . '    ', $output);
			$output = preg_replace('/,\s*/', ', ', $output);
			$output = preg_replace('/[ ]*}\s*/', '}' . "\n", $output);
			$output = preg_replace('/\}\s*(.+)/', '}' . "\n" . '$1', $output);
			$output = preg_replace('/\n    ([^:]+):\s*/', "\n" . '    $1: ', $output);
			$output = preg_replace('/([A-z0-9\)])}/', '$1;' . "\n" . '}', $output);

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