class LocationVO{
  String latitude;
  String longtitude;

  LocationVO(String latitude, String longtitude){
    this.latitude = latitude;
    this.longtitude = longtitude;
  }

  LocationVO.initial()
      : latitude = '';

}