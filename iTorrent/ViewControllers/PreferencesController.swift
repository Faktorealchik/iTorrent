//
//  PreferencesController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class PreferencesController : ThemedUIViewController {
    @IBOutlet var tableView: UITableView!
    
    var data : [Section] = []
    var onScreenPopup : PopupView?
    
    var _presentableData : [Section]?
    var presentableData : [Section] {
        get {
            if (_presentableData == nil) { _presentableData = [Section]() }
            _presentableData?.removeAll()
            data.forEach { _presentableData?.append(Section(rowModels: $0.rowModels.filter({ !($0.hiddenCondition?() ?? false)}), header: $0.header, footer: $0.footer)) }
            return _presentableData!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // APPEARENCE
        var appearence = [CellModelProtocol]()
        appearence.append(SegueCell.Model(self, title: "Settings.Order", segueViewId: "SettingsSortingController"))
        if #available(iOS 13, *) {
            appearence.append(SwitchCell.Model(title: "Settings.AutoTheme", defaultValue: { UserPreferences.autoTheme.value },
                                                       action: { switcher in
                                                        let oldTheme = Themes.current
                                                        UserPreferences.autoTheme.value = switcher.isOn
                                                        Themes.shared.currentUserTheme = UIApplication.shared.keyWindow?.traitCollection.userInterfaceStyle.rawValue
                                                        let newTheme = Themes.current
                                                        
                                                        if (oldTheme != newTheme) {
                                                            self.navigationController?.view.isUserInteractionEnabled = false
                                                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                                                                CircularAnimation.animate(startingPoint: switcher.superview!.convert(switcher.center, to: nil))
                                                                self.tableView.reloadData()
                                                                self.navigationController?.view.isUserInteractionEnabled = true
                                                            }
                                                        } else {
                                                            if let rvc = UIApplication.shared.keyWindow?.rootViewController as? Themed {
                                                                rvc.themeUpdate()
                                                            }
                                                            if (!switcher.isOn) {
                                                                self.tableView.insertRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
                                                            }
                                                            else {
                                                                self.tableView.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
                                                            }
                                                        }
            }))
        }
        appearence.append(SwitchCell.Model(title: "Settings.Theme",
                                           defaultValue: { UserPreferences.themeNum.value == 1 },
                                           hiddenCondition: { UserPreferences.autoTheme.value }) { switcher in
                                            self.navigationController?.view.isUserInteractionEnabled = false
                                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                                                UserPreferences.themeNum.value = switcher.isOn ? 1 : 0
                                                CircularAnimation.animate(startingPoint: switcher.superview!.convert(switcher.center, to: nil))
                                                self.navigationController?.view.isUserInteractionEnabled = true
                                            }
        })
        data.append(PreferencesController.Section(rowModels: appearence))
        
        //BACKGROUND
        var background = [CellModelProtocol]()
        background.append(SwitchCell.ModelProperty(title: "Settings.BackgroundEnable", property: UserPreferences.background) { _ in self.tableView.reloadData() })
        background.append(SwitchCell.Model(title: "Settings.BackgroundSeeding", defaultValue: { UserPreferences.backgroundSeedKey.value }, switchColor: #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1), disableCondition: { !UserPreferences.background.value }){ switcher in
            if (switcher.isOn) {
                let controller = ThemedUIAlertController(title: NSLocalizedString("WARNING", comment: ""), message: NSLocalizedString("This will let iTorrent run in in the background indefinitely, in case any torrent is seeding without limits, which can cause significant battery drain. \n\nYou will need to force close the app to stop this!", comment: ""), preferredStyle: .alert)
                let enable = UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .destructive) { _ in
                    UserPreferences.backgroundSeedKey.value = switcher.isOn
                }
                let close = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                    switcher.setOn(false, animated: true)
                }
                controller.addAction(enable)
                controller.addAction(close)
                self.present(controller, animated: true)
            } else {
                UserPreferences.seedBackgroundWarning.value = false
                UserPreferences.backgroundSeedKey.value = false
            }
        })
        data.append(PreferencesController.Section(rowModels: background, header: "Settings.BackgroundHeader", footer: "Settings.BackgroundFooter"))
        
        //SPEED LIMITATION
        var speed = [CellModelProtocol]()
        speed.append(ButtonCell.Model(title: "Settings.DownLimit",
                                      buttonTitle: UserPreferences.downloadLimit.value == 0 ?
                                        NSLocalizedString("Unlimited", comment: "") :
                                        Utils.getSizeText(size: UserPreferences.downloadLimit.value, decimals: true) + "/S")
        { button in
            self.onScreenPopup?.dismiss()
            self.onScreenPopup = SpeedPicker(defaultValue: UserPreferences.downloadLimit.value, dataSelected: { res in
                if (res == 0) {
                    button.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
                } else {
                    button.setTitle(Utils.getSizeText(size: res, decimals: true) + "/S", for: .normal)
                }
            }, dismissAction: { res in
                UserPreferences.downloadLimit.value = res
                set_download_limit(Int32(res))
            })
            self.onScreenPopup?.show(self)
        })
        speed.append(ButtonCell.Model(title: "Settings.UpLimit",
                                      buttonTitle: UserPreferences.uploadLimit.value == 0 ?
                                        NSLocalizedString("Unlimited", comment: "") :
                                        Utils.getSizeText(size: UserPreferences.uploadLimit.value, decimals: true) + "/S")
        { button in
            self.onScreenPopup?.dismiss()
            self.onScreenPopup = SpeedPicker(defaultValue: UserPreferences.uploadLimit.value, dataSelected: { res in
                if (res == 0) {
                    button.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
                } else {
                    button.setTitle(Utils.getSizeText(size: res, decimals: true) + "/S", for: .normal)
                }
            }, dismissAction: { res in
                UserPreferences.uploadLimit.value = res
                set_upload_limit(Int32(res))
            })
            self.onScreenPopup?.show(self)
        })
        data.append(PreferencesController.Section(rowModels: speed, header: "Settings.SpeedHeader"))
        
        //FTP
        var ftp = [CellModelProtocol]()
        ftp.append(SwitchCell.ModelProperty(title: "Settings.FTPEnable", property: UserPreferences.ftpKey) { switcher in
            switcher.isOn ? Manager.startFTP() : Manager.stopFTP()
            self.tableView.reloadData()
        })
        ftp.append(SwitchCell.Model(title: "Settings.FTPBackground", defaultValue: { UserPreferences.ftpBackgroundKey.value }, switchColor: #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1)) { switcher in
            if (switcher.isOn) {
                let controller = ThemedUIAlertController(title: NSLocalizedString("WARNING", comment: ""), message: NSLocalizedString("This will let iTorrent run in the background indefinitely, which can cause significant battery drain. \n\nYou will need to force close the app to stop this!", comment: ""), preferredStyle: .alert)
                let enable = UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .destructive) { _ in
                    UserPreferences.ftpBackgroundKey.value = switcher.isOn
                }
                let close = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                    switcher.setOn(false, animated: true)
                }
                controller.addAction(enable)
                controller.addAction(close)
                self.present(controller, animated: true)
            } else {
                UserPreferences.ftpBackgroundKey.value = switcher.isOn
            }
        })
        data.append(PreferencesController.Section(rowModels: ftp, header: "Settings.FTPHeader"))
        
        //NOTIFICATIONS
        var notifications = [CellModelProtocol]()
        notifications.append(SwitchCell.ModelProperty(title: "Settings.NotifyFinishLoad", property: UserPreferences.notificationsKey) { _ in self.tableView.reloadData() })
        notifications.append(SwitchCell.ModelProperty(title: "Settings.NotifyFinishSeed", property: UserPreferences.notificationsSeedKey) { _ in self.tableView.reloadData() })
        notifications.append(SwitchCell.ModelProperty(title: "Settings.NotifyBadge", property: UserPreferences.badgeKey, disableCondition: { !UserPreferences.notificationsKey.value && !UserPreferences.notificationsSeedKey.value }))
        data.append(PreferencesController.Section(rowModels: notifications, header: "Settings.NotifyHeader"))
        
        //UPDATES
        var updates = [CellModelProtocol]()
        updates.append(ButtonCell.Model(title: "Settings.UpdateSite", buttonTitle: "Settings.UpdateSite.Open") { button in
            Utils.openUrl("https://github.com/XITRIX/iTorrent")
        })
        updates.append(UpdateInfoCell.Model {
            self.present(Dialogs.crateUpdateDialog(forced: true)!, animated: true)
        })
        let version = try! String(contentsOf: Bundle.main.url(forResource: "Version", withExtension: "ver")!)
        data.append(PreferencesController.Section(rowModels: updates, header: "Settings.UpdateHeader", footer: NSLocalizedString("Current app version: ", comment: "") + version))
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onScreenPopup?.dismiss()
    }
    
    struct Section {
        var rowModels : [CellModelProtocol] = []
        var header : String = ""
        var footer : String = ""
    }
}

extension PreferencesController : UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return presentableData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presentableData[section].rowModels.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Localize.get(presentableData[section].header)
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return Localize.get(presentableData[section].footer)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = presentableData[indexPath.section].rowModels[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: model.reuseCellIdentifier, for: indexPath)
        (cell as? PreferenceCellProtocol)?.setModel(model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = presentableData[indexPath.section].rowModels[indexPath.row]
        model.tapAction?()
    }
}
