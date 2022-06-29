// req、res => https://nuxtjs.org/docs/2.x/internals-glossary/nuxt-render
export default (req, res, next) => {
  const { NODE_ENV, BASE_URL } = process.env

  // 本番環境 && BASE_URLが存在する場合
  if (NODE_ENV === 'production' && !!BASE_URL) {
    const redirectDomain = /herokuapp.com/
    const reqHost = req.headers.host
    // x-forwarded-proto(Herokuヘッダー): https://devcenter.heroku.com/articles/http-routing#heroku-headers
    const reqProtocol = req.headers['x-forwarded-proto']

    // SSLではない || リクエストホストにredirectDomainを含む場合
    if (reqProtocol === 'http' || redirectDomain.test(reqHost)) {
      const redirectTargetUrl = BASE_URL + req.url

      // リクエストに301(恒久的な転送)レスポンスヘッダーを送信する
      // { Location: 'リダイレクト先URL' }
      // Doc: https://nodejs.org/api/http.html#http_response_writehead_statuscode_statusmessage_headers
      res.writeHead(301, { Location: redirectTargetUrl })

      // リクエストの送信を終了する
      // end(data)が指定されている場合は、request.write(data, encoding)の後にrequest.end(callback)を呼び出したのと同じです。
      // callbackを指定した場合は、リクエストストリームが終了したときに呼び出されます。
      // Doc: https://nodejs.org/api/http.html#http_response_end_data_encoding_callback
      return res.end(redirectTargetUrl)
    }
  }
  return next()
}
