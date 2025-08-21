ARG BUILD_FROM
FROM $BUILD_FROM

# Copy data for add-on new 1
COPY rootfs /

# Install system dependencies using apk (Alpine package manager)
# Note: build-base is the Alpine equivalent of build-essential
# Note: openssl-dev is the Alpine equivalent of libssl-dev
# Note: Removing bluez version pin initially - add back if needed and available
RUN apk add --no-cache \
    git \
    build-base \
    python3-dev \
    libffi-dev \
    openssl-dev \
    cargo \
    bluez

# Install bluetti_mqtt and other pip packages
RUN pip install asyncio-mqtt==0.12.1 bleak==0.22.3 crcmod==1.7 cryptography==44.0.0 dbus-next==0.2.3 paho-mqtt==1.6.1 pyasn1==0.6.1
RUN pip install git+https://github.com/laho98/bluetti_mqtt

# Set permissions for run script
RUN chmod a+x /run.sh

RUN sed -i 's/sys.exit(main())/sys.exit(main(sys.argv))/' /usr/local/bin/bluetti-mqtt

# Optional: Clean apk cache if needed, though --no-cache minimizes it
# RUN rm -rf /var/cache/apk/*

CMD [ "/run.sh" ]
