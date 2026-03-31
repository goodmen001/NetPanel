import sys

zh_file = 'G:/Codes/NetPanelPage/webpage/src/i18n/locales/zh.ts'
en_file = 'G:/Codes/NetPanelPage/webpage/src/i18n/locales/en.ts'

# Update zh.ts
with open(zh_file, 'r', encoding='utf-8') as f:
    content = f.read()

old_zh = """    dnsWarningHint: '请先在「DNS 域名解析」中添加对应域名，再申请证书',
  },
  // 域名管理（域名列表）"""

new_zh = """    dnsWarningHint: '请先在「DNS 域名解析」中添加对应域名，再申请证书',
    downloadCert: '下载证书',
    status: '状态',
    statusPending: '待申请',
    statusCreatingOrder: '创建订单中',
    statusDnsSet: 'DNS已设置',
    statusValidating: '验证中',
    statusValid: '有效',
    statusExpired: '已过期',
    statusError: '出错',
    viewProgress: '查看进度',
    applySubmitted: '已触发证书申请，请稍后查看进度',
    stepSubmitted: '操作已提交',
    acmeFlowTitle: 'ACME 证书申请流程',
    step1Title: '创建订单',
    step1Desc: '获取挑战信息',
    step2Title: '设置DNS',
    step2Desc: '添加TXT记录',
    step3Title: '提交验证',
    step3Desc: '等待CA验证',
    step4Title: '获取证书',
    step4Desc: '下载并保存',
    currentStatus: '当前状态',
    currentStep: '当前步骤',
    nextAction: '下次自动执行',
    secondsLater: '秒后执行',
    executing: '即将执行',
    dnsRecordInfo: 'DNS 验证记录',
    dnsRecordName: '记录名',
    dnsRecordValue: '记录值',
    errorInfo: '错误信息',
    manualOps: '手动操作',
    manualOpsHint: '通常无需手动操作，系统会自动执行每个步骤。如果自动流程出错，可以手动重试对应步骤。',
    certAccountHint: 'ACME 申请必须选择预先注册的证书账号',
    certAccountPlaceholder: '请选择证书账号',
    autoRenewOn: '自动',
    autoRenewOff: '手动',
    apply: '申请证书',
    certContentRequired: '请粘贴证书内容',
    keyContentRequired: '请粘贴私钥内容',
    keyContentHint: 'PEM 格式私钥内容',
    renewBeforeDaysHint: '到期前多少天自动续期',
    days: '天',
    daysLeft: '天后到期',
    domainsAutoDetect: '域名列表（自动识别，可手动修改）',
    namePlaceholder: '证书名称',
    dnsAccount: 'DNS 账号',
    dnsAccountPlaceholder: '选择域名账号（可选）',
    dnsRecommended: '推荐，支持通配符',
  },
  // 域名管理（域名列表）"""

if old_zh in content:
    content = content.replace(old_zh, new_zh)
    with open(zh_file, 'w', encoding='utf-8') as f:
        f.write(content)
    print('zh.ts updated successfully')
else:
    print('ERROR: old_zh not found in zh.ts')

# Update en.ts
with open(en_file, 'r', encoding='utf-8') as f:
    content = f.read()

old_en = """    dnsWarningHint: 'Please add the domains in "DNS Records" first, then apply for the certificate',
  },
  domainInfo: {"""

new_en = """    dnsWarningHint: 'Please add the domains in "DNS Records" first, then apply for the certificate',
    downloadCert: 'Download Certificate',
    status: 'Status',
    statusPending: 'Pending',
    statusCreatingOrder: 'Creating Order',
    statusDnsSet: 'DNS Set',
    statusValidating: 'Validating',
    statusValid: 'Valid',
    statusExpired: 'Expired',
    statusError: 'Error',
    viewProgress: 'View Progress',
    applySubmitted: 'Certificate application submitted, please check progress later',
    stepSubmitted: 'Operation submitted',
    acmeFlowTitle: 'ACME Certificate Flow',
    step1Title: 'Create Order',
    step1Desc: 'Get challenge info',
    step2Title: 'Set DNS',
    step2Desc: 'Add TXT record',
    step3Title: 'Validate',
    step3Desc: 'Wait for CA',
    step4Title: 'Obtain Cert',
    step4Desc: 'Download & save',
    currentStatus: 'Current Status',
    currentStep: 'Current Step',
    nextAction: 'Next Auto Action',
    secondsLater: 's later',
    executing: 'Executing soon',
    dnsRecordInfo: 'DNS Validation Records',
    dnsRecordName: 'Record Name',
    dnsRecordValue: 'Record Value',
    errorInfo: 'Error Info',
    manualOps: 'Manual Operations',
    manualOpsHint: 'Usually no manual operation needed. The system will auto-execute each step. If the auto flow fails, you can manually retry the corresponding step.',
    certAccountHint: 'A pre-registered cert account is required for ACME',
    certAccountPlaceholder: 'Select cert account',
    autoRenewOn: 'Auto',
    autoRenewOff: 'Manual',
    apply: 'Apply Certificate',
    certContentRequired: 'Please paste certificate content',
    keyContentRequired: 'Please paste private key content',
    keyContentHint: 'PEM format private key',
    renewBeforeDaysHint: 'Days before expiry to auto-renew',
    days: 'days',
    daysLeft: ' days left',
    domainsAutoDetect: 'Domains (auto-detected, editable)',
    namePlaceholder: 'Certificate name',
    dnsAccount: 'DNS Account',
    dnsAccountPlaceholder: 'Select DNS account (optional)',
    dnsRecommended: 'Recommended, supports wildcard',
  },
  domainInfo: {"""

if old_en in content:
    content = content.replace(old_en, new_en)
    with open(en_file, 'w', encoding='utf-8') as f:
        f.write(content)
    print('en.ts updated successfully')
else:
    print('ERROR: old_en not found in en.ts')
