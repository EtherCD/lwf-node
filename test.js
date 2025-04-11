const i = require("./dist/lib.node");
const lwf = require("lwf");

const schema = new lwf.Schema({
	a: {
		isArray: true,
	},
});

const buf = i.encodeArray([345, "LOOOL", 345, 5, 534]);

console.log(lwf.decode(buf, schema));

// console.log(performanceTest(() => i.encodeArray([45398453784537, "Lol", true])));
// console.log(performanceTest(() => lwf.encode({ num: 45398453784537, str: "Lol", bool: true }, schema)));
