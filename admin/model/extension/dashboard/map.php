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
