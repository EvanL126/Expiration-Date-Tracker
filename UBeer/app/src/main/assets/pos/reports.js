(function(root){
 'use strict';
 const day=value=>{const d=new Date(value);return Number.isFinite(d.getTime())?[d.getFullYear(),String(d.getMonth()+1).padStart(2,'0'),String(d.getDate()).padStart(2,'0')].join('-'):'';};
 function summarize(invoices,core,from='',to=''){
  const included=value=>{const d=day(value);return !!d&&(!from||d>=from)&&(!to||d<=to);};
  const rows=invoices.filter(i=>i.finalized&&included(i.created));
  const totals={subtotal:0,total:0,paid:0,balance:0,credit:0,tax:0,salesTax:0,packs:0,units:0};
  const items=new Map(),days=new Map(),methods=new Map();
  for(const invoice of rows){const t=core.totals(invoice);for(const key of Object.keys(totals))totals[key]+=t[key];const key=day(invoice.created);const bucket=days.get(key)||{day:key,sales:0,orders:0};bucket.sales+=t.subtotal;bucket.orders++;days.set(key,bucket);
   for(const line of invoice.lines){const key=JSON.stringify([line.productId||'',line.name,line.pack,line.volume]);const item=items.get(key)||{name:line.name,pack:line.pack,volume:line.volume,packs:0,units:0,sales:0};item.packs+=line.qty;item.units+=line.qty*line.pack;item.sales+=line.price*line.qty;items.set(key,item);}
  }
  // Collection dates are independent of invoice dates: later partial payments belong to the day received.
  for(const invoice of invoices.filter(i=>i.finalized))for(const payment of invoice.payments){if(!included(payment.at))continue;const name=payment.method||'Other';const method=methods.get(name)||{name,amount:0,count:0};method.amount+=payment.amount;method.count++;methods.set(name,method);}
  const payments=[...methods.values()].sort((a,b)=>b.amount-a.amount);
  return {rows,totals,items:[...items.values()].sort((a,b)=>b.sales-a.sales),days:[...days.values()].sort((a,b)=>a.day.localeCompare(b.day)),payments,collected:payments.reduce((sum,p)=>sum+p.amount,0),average:rows.length?Math.round(totals.total/rows.length):0};
 }
 const api={day,summarize};if(typeof module==='object'&&module.exports)module.exports=api;else root.POSReports=api;
})(typeof globalThis!=='undefined'?globalThis:this);
