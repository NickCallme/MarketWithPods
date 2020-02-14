//
//  ViewController.swift
//  Market
//
//  Created by Nikita Kolmykov on 29.01.2020.
//  Copyright © 2020 Nikita Kolmykov. All rights reserved.
//

import UIKit
import AVFoundation
import QRCodeReader

class CashboxViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, QRCodeReaderViewControllerDelegate  {
   
    @IBOutlet weak var tableViewOutlet: UITableView!
    var identifier = "Product"
    
    // MARK: QR контроллер
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
            
            // Конфигурация контроллера
            $0.showTorchButton        = false
            $0.showSwitchCameraButton = false
            $0.showCancelButton       = true
            $0.showOverlayView        = true
            $0.rectOfInterest         = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Перезагрузка таблицы при входе
        tableViewOutlet.reloadData()
        // Добавление стола
        addTable()
        
    }
    
    
    
    // Добавить стол
    func addTable() {
        
        tableViewOutlet.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
        
        tableViewOutlet.delegate = self
        tableViewOutlet.dataSource = self
        
    }
    
    // MARK: - Методы QR Code Reader
      // Обработка данных с QR
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        
        // Переменные для вариаций
        let id = result.value
        let productCatalog = market.servicesAssembly.catalog.find(id)
        
        if productCatalog == nil {
            
            // Создание контроллера
            let alertControllerFail = UIAlertController(title: "", message: "", preferredStyle: .alert)
            alertControllerFail.title = "Ошибка"
            alertControllerFail.message = "По данному QR коду отсутствует продукт в каталоге"
            
            // Кнопка Ок
            let actionOK = UIAlertAction(title: "OK", style: .default) { (action) in
                
                //Запус сканирования
                self.readerVC.startScanning()
                
            }
            
            // Добавление кнопки
            alertControllerFail.addAction(actionOK)
            
            readerVC.present(alertControllerFail, animated: true, completion: nil)
            
        } else {
                    
                    
            // Создание алерт контроллера
            let alertController = UIAlertController(title: "", message: "", preferredStyle: .alert)
            alertController.title = "Количетво"
            alertController.message = "Укажите кол-во " + productCatalog!.name
                    
            // Кнопка Добавить
            let actionAdd = UIAlertAction(title: "Добавить", style: .default) { (action) in
                        
            // Переменные для вариации
            guard let countStr = alertController.textFields?[0].text else {return}
            guard let count = Double(countStr) else {return}
                        
            let productWarehouse = market.servicesAssembly.warehouse.findProduct(id: id)
                        
            if productWarehouse == nil {
                            
                // Создать алерт контроллер
                let alertControllerFail = UIAlertController(title: "", message: "", preferredStyle: .alert)
                alertControllerFail.title = "Ошибка"
                alertControllerFail.message = "На складе отсутствует продукт " + productCatalog!.name
                            
                // Кнопка ОК
                let actionOK = UIAlertAction(title: "OK", style: .default) { (action) in
                                
                    // Продолжить сканирование
                    self.readerVC.startScanning()
                                
                }
                            
                // Добавление кнопки ОК
                alertControllerFail.addAction(actionOK)
                            
                self.present(alertControllerFail, animated: true, completion: nil)
                            
            } else if count > productWarehouse!.1 {
                            
                // Создание алерт контроллера
                let alertControllerFail = UIAlertController(title: "", message: "", preferredStyle: .alert)
                alertControllerFail.title = "Ошибка"
                alertControllerFail.message = "На складе отсутсвует указанное количество " + productCatalog!.name
                            
                // Кнопка ОК
                let actionOK = UIAlertAction(title: "OK", style: .default) { (action) in
                                
                    // Продолжить сканирование
                    self.readerVC.startScanning()
                                
                }
                            
                // Добавление кнопки ОК
                alertControllerFail.addAction(actionOK)
                            
                self.present(alertControllerFail, animated: true, completion: nil)
                            
            } else {
                            
                // Добавление позиции в кассу
                market.cashMachine.addPosition(id: id, count: count)
                        
                self.tableViewOutlet.reloadData()
                            
                // Возвращение на кассу
                self.dismiss(animated: true, completion: nil)
                            
            }
                        
        }
        // Кнопка Отмена
        let actionCancel = UIAlertAction(title: "Отмена", style: .default) { (action) in
                        
            // Продолжить сканирование
            self.readerVC.startScanning()
                        
        }
        // Цвет кнопки отмена
        actionCancel.setValue(UIColor.red, forKey: "titleTextColor")
                    
        // Текстовое поле количества
        alertController.addTextField { (countTextField) in
                        
            countTextField.placeholder = "Количество"
                        
        }
                    
        // Добавление кнопки Добавить
        alertController.addAction(actionAdd)
        // Добавление кнопки Отмена
        alertController.addAction(actionCancel)
                    
            readerVC.present(alertController, animated: true, completion: nil)
                    
    }
                
}
            
    
      // Функция при нажатии кнопки Отмена
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        
        // Остановка сканирования
        readerVC.stopScanning()
        
        dismiss(animated: true, completion: nil)
        
    }
    
    

    
    
// MARK: - Методы таблицы
    // Кол-во возвращаемых ячеек
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return market.cashMachine.returnCheck().description().count
    }
    // Обработка ячейки
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let arrayObj = market.cashMachine.returnCheck().description()
        
        let cell = tableViewOutlet.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        cell.textLabel?.text = arrayObj[indexPath.row]
        
        return cell
        
    }
    
    // MARK: - Кнопка SCAN : Action
    @IBAction func scanAction(_ sender: Any) {
        
        // Реализация протокола контроллером QR
         readerVC.delegate = self

         // Стиль контроллера QR
         readerVC.modalPresentationStyle = .currentContext
        
         present(readerVC, animated: true, completion: nil)
        
    }
    
    
    //MARK: - Кнопка добавить позицию вручную : Action
    @IBAction func addPositionManuallyAction(_ sender: Any) {
        
        // Создание алерт контроллера
        let alertController = UIAlertController(title: "Добавление позиции", message: "Укажите ID и кол-во продукта", preferredStyle: .alert)
        
        // Кнопка добавить и ее функции
        let actionAdd = UIAlertAction(title: "Добавить", style: .default) { (action) in
            
            // Переменные для функции
            guard let id = alertController.textFields?.first?.text else {return}
            guard let countStr = alertController.textFields?.last?.text else {return}
            guard let count = Double(countStr) else {return}
            
            // Переменный для вариации
            let warehouseProduct = market.servicesAssembly.warehouse.findProduct(id: id)
            let catalogProduct = market.servicesAssembly.catalog.find(id)
            
            if catalogProduct == nil {
                
                // Создание алерт кнотроллера
                let alertControllerFail = UIAlertController(title: "", message: "", preferredStyle: .alert)
                alertControllerFail.title = "Ошибка"
                alertControllerFail.message = "По указанному ID не существует продукта"
                
                // Кнопка Ок
                let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
                
                // Добавление кнопки ОК
                alertControllerFail.addAction(actionOK)
                
                self.present(alertControllerFail, animated: true, completion: nil)
                
            } else if warehouseProduct == nil {
                
                // Создание алерт кнотроллера
                let alertControllerFail = UIAlertController(title: "", message: "", preferredStyle: .alert)
                alertControllerFail.title = "Ошибка"
                alertControllerFail.message = "Указанный товар отсутствует на складе"
                
                // Кнопка Ок
                let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
                
                // Добавление кнопки ОК
                alertControllerFail.addAction(actionOK)
                
                self.present(alertControllerFail, animated: true, completion: nil)
                
            } else if count > warehouseProduct!.1 {
                
                // Создание алерт кнотроллера
                let alertControllerFail = UIAlertController(title: "", message: "", preferredStyle: .alert)
                alertControllerFail.title = "Ошибка"
                alertControllerFail.message = "Недостаточно товара на складе"
                
                // Кнопка Ок
                let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
                
                // Добавление кнопки ОК
                alertControllerFail.addAction(actionOK)
                
                self.present(alertControllerFail, animated: true, completion: nil)
                
            } else {
                
                // Функция добавления позиции в чек
                market.cashMachine.addPosition(id: id, count: count)
                
                // Перезагрузка таблицы
                self.tableViewOutlet.reloadData()
            }
            
        }
        
        // Кнопка отмены
        let actionCancel = UIAlertAction(title: "Отмена", style: .default, handler: nil)
        // Цвет кнопки отмены
        actionCancel.setValue(UIColor.red, forKey: "titleTextColor")
        
        // Добавление поля для ID
        alertController.addTextField { (textFieldID) in
            textFieldID.placeholder = "ID Продукта"
        }
        // Добавление поля для Кол-ва
        alertController.addTextField { (textFieldCount) in
            textFieldCount.placeholder = "Количество"
        }
        
        // Добавление кнопки ДОБАВИТЬ
        alertController.addAction(actionAdd)
        // Добавление кнопки ОТМЕНА
        alertController.addAction(actionCancel)
        
        
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - Кнопка оплаты безналичными
    @IBAction func cashlessAction(_ sender: Any) {
        
        // Получение чека для проверки
        let check = market.cashMachine.returnCheck().returnData()
        
        if check.count == 0 {
            
            // Создание алерт контроллера
            let alertControllerFail = UIAlertController(title: "", message: "", preferredStyle: .alert)
            alertControllerFail.title = "Ошибка"
            alertControllerFail.message = "В чеке отсутствуют продукты"
            
            // Кнопка ОК
            let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            // Добавление кнопки ОК
            alertControllerFail.addAction(actionOK)
            
            present(alertControllerFail, animated: true, completion: nil)
            
        } else {
            
            //Создани алерт контроллера
            let alerControllerAccept = UIAlertController(title: "Оплата", message: "Подтвердите безналичную оплату", preferredStyle: .alert)
            //Кнопка подтверждения
            let actionAccept = UIAlertAction(title: "Подтвердить", style: .default) { (accept) in
                
                // Оплата безналичными и получение чека
                let check = market.cashMachine.purchaseCashless()
                // Перезагрузка таблицы
                self.tableViewOutlet.reloadData()
                
                // Сообщение для алерт контроллера
                var messegeForAlert = String()
                
                // Цикл для обработки сообщения в алерт контроллер
                for line in check {
                    
                    messegeForAlert.append(line + "\n")
                    
                }
                
                // Cоздание алерт контроллера
                let alertControllerOK = UIAlertController(title: "ЧЕК", message: messegeForAlert, preferredStyle: .alert)
                // Создание кнопки ОК
                let alertActionOK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                // Добавление кнопки ОК
                alertControllerOK.addAction(alertActionOK)
                
                self.present(alertControllerOK, animated: true, completion: nil)
                
            }
            
            // Кнопка отмены
            let actionCancel = UIAlertAction(title: "Отмена", style: .default, handler: nil)
            // Цвет кнопки отмены
            actionCancel.setValue(UIColor.red, forKey: "titleTextColor")
            
            // Добавление кнопки подтвердить
            alerControllerAccept.addAction(actionAccept)
            // Добавления кнопки отмена
            alerControllerAccept.addAction(actionCancel)
            
            present(alerControllerAccept, animated: true, completion: nil)
            
        }
        
    }
    
    
    //MARK: - Кнопка оплаты наличными : Action
    @IBAction func cashAction(_ sender: Any) {
        
        // Получение чека для проверки
        let check = market.cashMachine.returnCheck().returnData()
        
        if check.count == 0 {
            
            // Создание алерт контроллера
            let alertControllerFail = UIAlertController(title: "", message: "", preferredStyle: .alert)
            alertControllerFail.title = "Ошибка"
            alertControllerFail.message = "В чеке отсутствуют продукты"
            
            // Кнопка ОК
            let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            // Добавление кнопки ОК
            alertControllerFail.addAction(actionOK)
            
            present(alertControllerFail, animated: true, completion: nil)
            
        } else {
            
            //Создани алерт контроллера
            let alerControllerAccept = UIAlertController(title: "Оплата", message: "Подтвердите наличную оплату", preferredStyle: .alert)
            //Кнопка подтверждения
            let actionAccept = UIAlertAction(title: "Подтвердить", style: .default) { (accept) in
                
                // Оплата безналичными и получение чека
                let check = market.cashMachine.purchaseCash()
                // Перезагрузка таблицы
                self.tableViewOutlet.reloadData()
                
                // Сообщение для алерт контроллера
                var messegeForAlert = String()
                
                // Цикл для обработки сообщения в алерт контроллер
                for line in check {
                    
                    messegeForAlert.append(line + "\n")
                    
                }
                
                // Cоздание алерт контроллера
                let alertControllerOK = UIAlertController(title: "ЧЕК", message: messegeForAlert, preferredStyle: .alert)
                // Создание кнопки ОК
                let alertActionOK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                // Добавление кнопки ОК
                alertControllerOK.addAction(alertActionOK)
                
                self.present(alertControllerOK, animated: true, completion: nil)
                
            }
            
            // Кнопка отмены
            let actionCancel = UIAlertAction(title: "Отмена", style: .default, handler: nil)
            // Цвет кнопки отмены
            actionCancel.setValue(UIColor.red, forKey: "titleTextColor")
            
            // Добавление кнопки подтвердить
            alerControllerAccept.addAction(actionAccept)
            // Добавления кнопки отмена
            alerControllerAccept.addAction(actionCancel)
            
            present(alerControllerAccept, animated: true, completion: nil)
            
        }
        
    }
    
    //MARK: - Кнопка удалить позицию : Action
    @IBAction func deletePositionAction(_ sender: Any) {
        
        // ID для удаления позиции
        var id = String()
        // Кол-во для удаление из позиции
        var count = Double()
        
        // Создание алерт контроллера
        let alertController = UIAlertController(title: "Удаление позиции", message: "Укажите ID и кол-во продукта", preferredStyle: .alert)
        
        // Кнопка удалить и ее функции
        let actionAdd = UIAlertAction(title: "Удалить", style: .default) { (action) in
            
            guard let text = alertController.textFields?.first?.text else {return}
            id = text
            guard let quantity = alertController.textFields?.last?.text else {return}
            guard let quantityDouble = Double(quantity) else {return}
            count = quantityDouble
            
            // Функция удаления позиции из чека
            market.cashMachine.deletePosition(id: id, count: count)
            
            // Перезагрузка таблицы
            self.tableViewOutlet.reloadData()
        }
        // Цвет кнопки удалить
        actionAdd.setValue(UIColor.red, forKey: "titleTextColor")
        
        // Кнопка отмены
        let actionCancel = UIAlertAction(title: "Отмена", style: .default, handler: nil)
        
        // Добавление поля для ID
        alertController.addTextField { (textFieldID) in
            textFieldID.placeholder = "ID Продукта"
        }
        // Добавление поля для Кол-ва
        alertController.addTextField { (textFieldCount) in
            textFieldCount.placeholder = "Количество"
        }
        
        // Добавление кнопки ДОБАВИТЬ
        alertController.addAction(actionAdd)
        // Добавление кнопки ОТМЕНА
        alertController.addAction(actionCancel)
        
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    //MARK: - Кнопка отмены покупки : Action
    @IBAction func cancelPayAction(_ sender: Any) {
        
        // Создаю алерт контроллер
        let alertController = UIAlertController(title: "Отмена", message: "Подтвердите отмену чека", preferredStyle: .alert)
        // Кнопка подтвердить и ее функция
        let actionAccept = UIAlertAction(title: "Подтвердить", style: .default) { (action) in
            
            // Отмена чека
            market.cashMachine.cancelPurchase()
            // Обновление таблицы
            self.tableViewOutlet.reloadData()
            
        }
        // Цвет кнопки подтвердить
        actionAccept.setValue(UIColor.red, forKey: "titleTextColor")
        
        
        // Кнопка отмены
        let actionCancel = UIAlertAction(title: "Отмена", style: .default, handler: nil)
        
        // Добваление кнопки подтвердить
        alertController.addAction(actionAccept)
        // Добавление кнопки отмена
        alertController.addAction(actionCancel)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    
    //MARK: - Кнопка выйти : Action
    @IBAction func exitAction(_ sender: Any) {
        
        // Создание алерт контроллера
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .alert)
        alertController.title = "Выход"
        alertController.message = "Вы уврены что хотите выйти?"
        
        // Кнопка Да
        let actionYes = UIAlertAction(title: "Да", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        // Цвет кнопки да
        actionYes.setValue(UIColor.red, forKey: "titleTextColor")
        
        // Кнопка Нет
        let actionNo = UIAlertAction(title: "Нет", style: .default, handler: nil)
        
        // Добавление кнопки ДА
        alertController.addAction(actionYes)
        // Добавление кнопки НЕТ
        alertController.addAction(actionNo)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    
    

}


