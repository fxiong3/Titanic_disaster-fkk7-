FROM r-base:4.3.2

WORKDIR /app

# install the small libraries
COPY install_packages.R .
RUN Rscript install_packages.R

# your script
COPY titanic.R .

CMD ["Rscript", "titanic.R"]
