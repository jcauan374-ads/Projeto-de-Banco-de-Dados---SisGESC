DELIMITER $$

CREATE TRIGGER tr_funcionario_demissao
BEFORE UPDATE ON tb_funcionarios
FOR EACH ROW
BEGIN
 IF NEW.status_funcionario = 'inativo' AND NEW.data_demissao IS NULL THEN
 SIGNAL SQLSTATE '45000'
 SET MESSAGE_TEXT = 'Informe a data de demissão.';
 END IF;
END$$

DELIMITER ;
