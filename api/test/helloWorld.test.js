const request = require("supertest");
const app = require("../app");

describe("Validate api", () => {
  test("GET /hello", async (done) => {
    const response = await request(app).get("/api/hello");

    expect(response.statusCode).toBe(200);
    expect(response.text).toStrictEqual('Hello World!');

    done();
  });
});