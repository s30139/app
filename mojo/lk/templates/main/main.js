//
function goods(r) {
    console.log('work goods');
    console.dir( r );
    return r.goods;
}
function inc(o, n) {
    console.log('work inc');
    console.dir( o );
    console.dir( n );

    console.log('for array');
    o.forEach( function( item , i , arr ) {
        console.log('el ' + i);
        console.dir(item);
        if ( item.id === n.id ) {
            item.count = n.count;
        }
    });
}

// vue.js
var app = new Vue({
  el: '#main',
  data: {
    goods:  [],
    orders: []
  },
  methods: {
    GetGoods: function () {
        axios.post( location.pathname, {
            action: "goods"
        })
        .then(response => (this.goods = goods(response.data) ));
    },
    GetOrders: function () {
        axios.post( location.pathname, {
            action: "orders"
        })
        .then(r => {
            this.orders = r.data.orders;
            console.dir(r.data.orders);
        });
    },
    Increment: function (event) {
        //console.dir(event);
        var id = event.target.id;
        console.log('btn id <' + id + '>');
        axios.post( '/api/increment/' + id )
        .then(r => { inc(this.orders, r.data); });
    },
    Remove: function (event) {
        //console.dir(event);
        var id = event.target.id;
        console.log('btn id <' + id + '>');
        axios.post( '/api/remove/' + id )
        .then(r => { this.GetOrders(); } );
    },
    Pay: function (event) {
        var id = event.target.id;
        axios.post( '/api/pay/' + id )
        .then(r => { this.GetOrders(); } );
    }
  },
    beforeMount(){
        this.GetGoods();
        this.GetOrders();
    },

})
