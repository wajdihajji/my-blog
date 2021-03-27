FROM node:12 as react-build
WORKDIR /app 

# COPY the package.json file, update any deps and install them
COPY package.json . 

RUN npm install

COPY . ./

RUN npm run build

# server environment
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/configfile.template

COPY --from=react-build /app/public /usr/share/nginx/html

ENV PORT 8080
ENV HOST 0.0.0.0
EXPOSE 8080
CMD sh -c "envsubst '\$PORT' < /etc/nginx/conf.d/configfile.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
