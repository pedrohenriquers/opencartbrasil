<?php
class ModelExtensionDashboardMap extends Model {
	public function getTotalOrdersByCountry() {
		$status = $this->getCompleteStatusIn();

		if (!$status) {
			return array();
		}

		$query = $this->db->query("SELECT COUNT(*) AS total, SUM(o.total) AS amount, c.iso_code_2 FROM `" . DB_PREFIX . "order` o LEFT JOIN `" . DB_PREFIX . "country` c ON (o.payment_country_id = c.country_id) WHERE o.order_status_id IN(" . $status . ") GROUP BY o.payment_country_id");

		return $query->rows;
	}

	public function getTotalOrdersByState() {
		$status = $this->getCompleteStatusIn();

		if (!$status) {
			return array();
		}

		$query = $this->db->query("SELECT COUNT(*) AS total, SUM(o.total) AS amount, o.shipping_zone AS zone FROM `" . DB_PREFIX . "order` o WHERE o.order_status_id IN(" . $status . ") AND o.shipping_zone != '' GROUP BY o.shipping_zone");

		return $query->rows;
	}

	public function getTotalOrdersByCity($zone) {
		$status = $this->getCompleteStatusIn();

		if (!$status) {
			return array();
		}

		$query = $this->db->query("SELECT COUNT(*) AS total, SUM(o.total) AS amount, o.shipping_city AS city FROM `" . DB_PREFIX . "order` o WHERE o.order_status_id IN(" . $status . ") AND o.shipping_zone = '" . $this->db->escape($zone) . "' AND o.shipping_city != '' GROUP BY o.shipping_city ORDER BY total DESC");

		return $query->rows;
	}

	/**
	 * Nome do estado, como gravado no pedido, para o código da região no
	 * jqvmap. O mapa numera os 27 estados em ordem alfabética, de br-01 a
	 * br-27, e os nomes abaixo são exatamente os do arquivo do mapa.
	 */
	public function getStateMapCodes() {
		return array(
			'Acre'                => 'br-01',
			'Alagoas'             => 'br-02',
			'Amapá'               => 'br-03',
			'Amazonas'            => 'br-04',
			'Bahia'               => 'br-05',
			'Ceará'               => 'br-06',
			'Distrito Federal'    => 'br-07',
			'Espírito Santo'      => 'br-08',
			'Goiás'               => 'br-09',
			'Maranhão'            => 'br-10',
			'Mato Grosso'         => 'br-11',
			'Mato Grosso do Sul'  => 'br-12',
			'Minas Gerais'        => 'br-13',
			'Pará'                => 'br-14',
			'Paraíba'             => 'br-15',
			'Paraná'              => 'br-16',
			'Pernambuco'          => 'br-17',
			'Piauí'               => 'br-18',
			'Rio de Janeiro'      => 'br-19',
			'Rio Grande do Norte' => 'br-20',
			'Rio Grande do Sul'   => 'br-21',
			'Rondônia'            => 'br-22',
			'Roraima'             => 'br-23',
			'Santa Catarina'      => 'br-24',
			'São Paulo'           => 'br-25',
			'Sergipe'             => 'br-26',
			'Tocantins'           => 'br-27'
		);
	}

	/**
	 * IDs dos status que a loja considera concluídos, prontos para um IN().
	 *
	 * O código anterior fazia IN('" . (int)implode(',', $implode) . "'), e o
	 * cast se aplica ao resultado do implode: "5,3" vira 5. Com mais de um
	 * status configurado, todos menos o primeiro eram descartados em silêncio.
	 */
	private function getCompleteStatusIn() {
		$implode = array();

		if (is_array($this->config->get('config_complete_status'))) {
			foreach ($this->config->get('config_complete_status') as $order_status_id) {
				$implode[] = (int)$order_status_id;
			}
		}

		return implode(',', $implode);
	}
}
