const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const root = path.join(__dirname, '../app/src/main/assets/pos');
const core = require(path.join(root, 'core.js'));
function app(options={}) {
  const elements = new Map();
  const element = id => {
    if (!elements.has(id)) elements.set(id, {value:'',checked:false,style:{},textContent:'',innerHTML:'',focus(){},querySelector(){return null;},showModal(){this.open=true;},close(){this.open=false;},addEventListener(){}});
    return elements.get(id);
  };
  let saved = null, printed = null, recovery=null; const requests=[];
  const ctx = vm.createContext({console,POSCore:core,POSReports:require(path.join(root,'reports.js')),document:{body:{classList:{add(){},remove(){}}},getElementById:element,querySelectorAll:()=>[],querySelector:()=>null},window:{NativePOS:true},NativePOS:{load:()=>saved,save:s=>{saved=s;return true;},saveRecovery:s=>{recovery=s;return !options.failRecovery;},loadRecovery:()=>recovery,printInvoice:(html,name)=>{printed={html,name};}},setTimeout:()=>0,clearTimeout(){},alert:m=>{throw Error(m);},confirm:()=>true});
  if(options.cloud){ctx.FirebasePOS={statusJson:()=>JSON.stringify({configured:true,signedIn:true,email:'owner@example.com',project:'beer-b74cb'}),request:(action,payload)=>requests.push({action,payload:JSON.parse(payload)})};vm.runInContext(fs.readFileSync(path.join(root,'cloud.js'),'utf8'),ctx);ctx.CloudPOS=ctx.window.CloudPOS;ctx.window.NativePOS=ctx.NativePOS;}
  vm.runInContext(fs.readFileSync(path.join(root,'app.js'),'utf8'),ctx);
  return {run:s=>vm.runInContext(s,ctx),element,saved:()=>JSON.parse(saved),printed:()=>printed,requests,recovery:()=>recovery};
}
test('similar names offer choices, exact names and saved barcodes resolve predictably',()=>{
  const products=[{name:'Cola',barcode:'001234'},{name:'Cola Zero',barcode:'001235'},{name:'Cola',barcode:'001236'}];
  assert.equal(core.lookup(products,'col').matches.length,3);
  assert.equal(core.lookup(products,'cola').exact.length,2);
  assert.equal(core.lookup(products,'001234').exact[0],products[0]);
  assert.equal(core.lookup(products,' COLA ZERO ').exact[0],products[1]);
  assert.throws(()=>core.validateProduct({id:'new',name:'Duplicate',barcode:'001234',pack:24,price:100,sugarTax:0},products));
});
test('whole sale lifecycle: barcode, partial payment, finalization, later edits, receipt and deletion',()=>{
  const a=app();
  for(const [id,value] of Object.entries({'product-name':'Cola','barcode':'001234','product-price':'12.50',pack:'24',volume:'355 mL',category:'Soda','sugar-tax':'0.005',ounces:'10','sales-tax':'0'}))a.element(id).value=value;
  a.element('soda').checked=true;a.run('saveProduct(null)');
  a.run("query='001234';submitScan();query='001234';submitScan()");
  assert.equal(a.saved().draft.lines[0].qty,2);
  assert.equal(a.run('C.totals(current).total'),2740);
  a.element('payment').value='10';a.element('method').value='Cash';a.run('savePayment()');
  assert.equal(a.run('C.totals(current).balance'),1740);
  a.element('customer-name').value='Example Market';a.element('customer-phone').value='555-0100';a.element('customer-address').value='10 Main Street';a.run('saveCustomer();finalizeInvoice()');
  assert.equal(a.saved().invoices.length,1);assert.equal(a.saved().invoices[0].number,1001);
  // Changing the catalog preserves the original invoice snapshot.
  a.run("db.products[0].price=9999;db.products[0].volume='500 mL';persist()");
  assert.equal(a.run('current.lines[0].price'),1250);
  a.element('price').value='3';a.run('savePrice(0)');
  assert.equal(a.run('C.totals(current).credit'),160);
  a.run('printInvoice()');
  const html=a.printed().html;
  for(const text of ['Example Market','10 Main Street','355 mL','48 individual units','2 packs','Customer credit','Soda sugar tax'])assert.ok(html.includes(text),text);
  assert.ok(!html.includes('Tax ID'));assert.ok(!html.includes('Find your products'));assert.ok(!html.includes('<button'));
  a.run("openInvoice(current.id);addProduct(db.products[0].id)");
  assert.equal(a.saved().invoices[0].lines.length,2);
  a.run('removeLine(1)');assert.equal(a.saved().invoices[0].lines.length,1);
  a.run('deleteInvoice(current.id)');assert.equal(a.saved().invoices.length,0);
});
test('fractional pack quantities and excessive payments are rejected',()=>{
  const a=app();a.run("db.products.push({id:'p1',name:'Water',barcode:'123',price:1000,pack:12,volume:'500 mL',category:'Water',soda:false,sugarTax:200});addProduct('p1');changeQty(0,1.5)");
  assert.equal(a.run('current.lines[0].qty'),1);assert.equal(a.run('C.totals(current).tax'),0);
  a.element('payment').value='11';a.run('savePayment()');assert.equal(a.run('current.payments.length'),0);
});
test('camera result adds only an exact barcode; unknown codes are offered for saving',()=>{
  const a=app();
  a.run("db.products.push({id:'p1',name:'Cola',barcode:'001234',price:1000,pack:24,volume:'355 mL',category:'Soda',soda:false,sugarTax:0})");
  a.run("window.onCameraBarcode('001234')");
  assert.equal(a.run('current.lines[0].qty'),1);
  a.run("window.onCameraBarcode('001234')");
  assert.equal(a.run('current.lines[0].qty'),2);
  a.run("window.onCameraBarcode('0012')");
  assert.equal(a.run('current.lines[0].qty'),2);
  assert.equal(a.element('barcode').value,'0012');
  a.run("window.onCameraBarcode('AB-007')");
  assert.equal(a.element('barcode').value,'AB-007');
  a.run("productEditor('p1');window.onCameraBarcode('NEW-CODE','product')");
  assert.equal(a.element('barcode').value,'NEW-CODE');
  assert.equal(a.run('current.lines[0].qty'),2);
});
test('unknown scans open a closable form without a native dialog blocking the workspace',()=>{
  const a=app();
  a.run("window.onCameraBarcode('NEW-001')");
  assert.equal(a.element('modal-overlay').hidden,false);
  assert.equal(a.element('dialog').open,true);
  assert.ok(a.element('dialog-content').innerHTML.includes('Save product'));
  assert.ok(a.element('dialog-content').innerHTML.includes('Close dialog'));
  a.run('closeDialog()');
  assert.equal(a.element('modal-overlay').hidden,true);
  assert.equal(a.element('dialog').open,false);
  a.run("window.onCameraBarcode('NEW-002')");
  assert.equal(a.element('modal-overlay').hidden,false);
  assert.equal(a.element('barcode').value,'NEW-002');
  a.run('closeDialog();navigate("products")');
  assert.equal(a.element('modal-overlay').hidden,true);
});
test('custom categories persist, filter products, and survive backup restore',()=>{
  const a=app();
  a.element('new-category').value="Juice & Mixers";a.run('addCategory()');
  assert.ok(a.saved().categories.includes('Juice & Mixers'));
  a.element('new-category').value=' juice & mixers ';a.run('addCategory()');
  assert.equal(a.saved().categories.filter(c=>c==='Juice & Mixers').length,1);
  for(const [id,value] of Object.entries({'product-name':'Orange Juice',barcode:'0099','product-price':'15',pack:'12',volume:'1 L',category:'Juice & Mixers','sugar-tax':'0'}))a.element(id).value=value;
  a.run('saveProduct(null);selectCategory(db.categories.indexOf("Juice & Mixers")+1)');
  assert.ok(a.element('product-grid').innerHTML.includes('Orange Juice'));
  a.element('backup').value=JSON.stringify(a.saved());a.run('restoreBackup()');
  assert.ok(a.saved().categories.includes('Juice & Mixers'));
  assert.equal(a.saved().products[0].category,'Juice & Mixers');
  a.run('productEditor(db.products[0].id)');
  assert.ok(a.element('dialog-content').innerHTML.includes('Juice &amp; Mixers'));
});
test('ounce-based sugar tax and sales tax recalculate with quantity and invoice price',()=>{
  const p={id:'taxed',name:'Soda',barcode:'001',price:2000,pack:24,volume:'12 fl oz',ounces:12,soda:true,sugarTax:288,sugarRateMicros:core.rate('0.01'),salesTaxBps:core.salesRate('8.25')};
  const invoice={lines:[core.makeLine(p)],payments:[]};
  invoice.lines[0].qty=2;
  let t=core.totals(invoice);
  assert.equal(t.tax,576);assert.equal(t.salesTax,330);assert.equal(t.total,4906);
  invoice.payments.push({amount:2000});assert.equal(core.totals(invoice).balance,2906);
  invoice.lines[0].price=1000;t=core.totals(invoice);
  assert.equal(t.salesTax,165);assert.equal(t.tax,576);assert.equal(t.total,2741);
  const subcent=core.makeLine({...p,sugarRateMicros:core.rate('0.005')});
  assert.equal(core.lineSugar(subcent),144);
  assert.ok(Math.abs(core.ounces('355 mL')-12.004)<0.01);
  assert.equal(core.ounces('12 fl oz'),12);
  assert.throws(()=>core.validateProduct({...p,ounces:0},[]));
});
test('removing a catalog product preserves invoice items and the current page',()=>{
  const a=app();
  a.run("db.products.push({id:'p1',name:'Water',barcode:'001',price:1000,pack:12,volume:'500 mL',soda:false,sugarTax:0});addProduct('p1');current.customer.name='Market';finalizeInvoice();deleteProduct('p1')");
  assert.equal(a.saved().products.length,0);
  assert.equal(a.saved().invoices[0].lines[0].name,'Water');
  assert.equal(a.run('page'),'pos');
  assert.equal(a.element('modal-overlay').hidden,true);
});
test('customer database searches, selects, edits, and preserves historical invoice details',()=>{
  const a=app();
  for(const [id,value] of Object.entries({'customer-name':'Market One','customer-phone':'555-0101','customer-email':'market@example.com','customer-address':'1 Main St','customer-tax-id':'TAX-001'}))a.element(id).value=value;
  a.run('saveCustomer();saveCustomer()');assert.equal(a.saved().customers.length,1);
  a.run("db.products.push({id:'p1',name:'Water',barcode:'001',price:1000,pack:12,volume:'500 mL',soda:false,sugarTax:0});addProduct('p1');finalizeInvoice();newSale();useCustomer(db.customers[0].id)");
  assert.equal(a.saved().draft.customer.taxId,'TAX-001');
  a.run("customerQuery='555-0101';navigate('customers')");
  assert.ok(a.element('customer-list').innerHTML.includes('Market One'));
  a.element('customer-address').value='2 New St';a.run('saveCustomer(db.customers[0].id,true)');
  assert.equal(a.saved().customers[0].address,'2 New St');
  assert.equal(a.saved().invoices[0].customer.address,'1 Main St');
  a.run('customerHistory(db.customers[0].id)');
  assert.ok(a.element('dialog-content').innerHTML.includes('Invoice #1001'));
  assert.ok(!a.run('receiptMarkup(db.invoices[0])').includes('TAX-001'));
  a.element('backup').value=JSON.stringify(a.saved());a.run('restoreBackup()');
  assert.equal(a.saved().customers[0].taxId,'TAX-001');
});
test('existing invoice customers are imported into the directory once',()=>{
  const a=app();
  a.run("db.invoices.push({id:'old',customer:{name:'Previous Customer',phone:'123',email:'',address:'',taxId:''},created:new Date().toISOString()});normalizeCustomers(db);normalizeCustomers(db);persist()");
  assert.equal(a.saved().customers.length,1);
  assert.equal(a.saved().invoices[0].customerId,a.saved().customers[0].id);
});




test('clear search restores customers and clearing an order preserves payment and customer records',()=>{
 const a=app();
 a.run("db.products.push({id:'p1',name:'Water',barcode:'123',price:1000,pack:12,volume:'500 mL',category:'Water',soda:false,sugarTax:0});addProduct('p1')");
 a.element('customer-name').value='Market';a.run('saveCustomer()');
 a.element('payment').value='5';a.element('method').value='Cash';a.run('savePayment();finalizeInvoice()');
 a.run("customerQuery='missing';customerPicker();clearCustomerSearch(true)");
 assert.equal(a.element('customer-search').value,'');assert.ok(a.element('customer-picker-list').innerHTML.includes('Market'));
 a.run('closeDialog();clearOrder()');
 assert.equal(a.saved().invoices[0].lines.length,0);assert.equal(a.saved().invoices[0].payments[0].amount,500);
 assert.equal(a.saved().invoices[0].customer.name,'Market');assert.equal(a.saved().customers.length,1);
 assert.equal(a.run('C.totals(current).credit'),500);
 assert.ok(a.element('content').innerHTML.includes('Clear order'));
});

test('cloud backup uploads only on request and waits for a server result',()=>{
 const a=app({cloud:true});assert.equal(a.requests.length,0);
 a.run("navigate('settings');CloudPOS.backup()");assert.equal(a.requests[0].action,'backup');assert.ok(a.requests[0].payload.json.includes('invoices'));
 assert.ok(a.element('cloud-status').textContent.includes('Uploading'));
 a.run("CloudPOS.receive({action:'backup',ok:false,error:'Permission denied'})");assert.equal(a.element('cloud-status').textContent,'Permission denied');
 a.run("CloudPOS.backup();CloudPOS.receive({action:'backup',ok:true,data:'backup1'})");assert.ok(a.element('cloud-status').textContent.includes('Backup saved'));
});
test('cloud restore validates data and preserves a recovery copy',()=>{
 const a=app({cloud:true});const original=a.saved();const restored={...original,settings:{...original.settings,business:'Cloud Market'}};
 a.run("CloudPOS.restore('backup1')");a.run('CloudPOS.receive('+JSON.stringify({action:'restore',ok:true,data:JSON.stringify(restored)})+')');
 assert.equal(a.saved().settings.business,'Cloud Market');assert.equal(JSON.parse(a.recovery()).settings.business,original.settings.business);
 a.run('CloudPOS.recover()');assert.equal(a.saved().settings.business,original.settings.business);
});
test('cloud restore stops when local data changes or recovery cannot be saved',()=>{
 for(const failRecovery of [false,true]){
 const a=app({cloud:true,failRecovery});const restored=a.saved();restored.settings.business='Remote';a.run("CloudPOS.restore('backup1')");
 if(!failRecovery)a.run("db.settings.business='Edited locally';persist()");
 a.run('CloudPOS.receive('+JSON.stringify({action:'restore',ok:true,data:JSON.stringify(restored)})+')');
 assert.notEqual(a.saved().settings.business,'Remote');
 }
 const a=app({cloud:true});a.run("CloudPOS.restore('backup1');CloudPOS.receive({action:'restore',ok:true,data:'{}'})");assert.equal(a.saved().settings.business,'UBeer Wholesale');
});

test('sales reports separate invoice sales from later collections and keep item sizes distinct',()=>{
 const reports=require(path.join(root,'reports.js'));
 const line={productId:'p',name:'Water',qty:2,price:1000,pack:12,volume:'500 mL',sugarTax:0,salesTaxBps:500};
 const invoice={finalized:true,created:'2026-10-01T12:00:00',lines:[line],payments:[{at:'2026-10-05T12:00:00',amount:500,method:'Cash'}]};
 let r=reports.summarize([invoice,{...invoice,finalized:false}],core,'2026-10-01','2026-10-01');
 assert.equal(r.rows.length,1);assert.equal(r.totals.subtotal,2000);assert.equal(r.totals.salesTax,100);assert.equal(r.average,2100);assert.equal(r.collected,0);assert.equal(r.totals.balance,1600);
 r=reports.summarize([invoice],core,'2026-10-05','2026-10-05');assert.equal(r.rows.length,0);assert.equal(r.collected,500);assert.equal(r.payments[0].name,'Cash');
 invoice.lines.push({...line,pack:24,qty:1});r=reports.summarize([invoice],core);assert.equal(r.items.length,2);assert.equal(r.totals.units,48);
});
test('combined workspace and report views render with no separate phone cart tab',()=>{
 const a=app();assert.ok(a.element('content').innerHTML.includes('sale-workspace'));assert.ok(!a.element('content').innerHTML.includes('phone-sale-tabs'));
 a.run("navigate('reports')");assert.ok(a.element('content').innerHTML.includes('Sales trends'));
 a.run("reportTab='payments';renderReports()");assert.ok(a.element('content').innerHTML.includes('No activity in this date range'));
 a.run("reportPreset('week')");assert.match(a.run('reportFrom'),/^\d{4}-\d{2}-\d{2}$/);
});
