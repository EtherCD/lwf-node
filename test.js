const i = require("./dist/lib.node");
const lwf = require("lwf");

// const schema = new lwf.Schema({
// 	a: {
// 		fields: ["num", "str", "bool"],
// 	},
// });

const buf = i.encodeInt64(-200);

const performanceTest = (call) => {
	const t = Date.now();
	let o = 0;
	while (Date.now() - t < 1000) {
		o++;
		call();
	}
	return o;
};

console.log(performanceTest(() => i.encodeInt64(-200)));
console.log(performanceTest(() => i.decodeInt64(buf)));

// console.log(performanceTest(() => i.encodeArray([45398453784537, "Lol", true])));
// console.log(performanceTest(() => lwf.encode({ num: 45398453784537, str: "Lol", bool: true }, schema)));
