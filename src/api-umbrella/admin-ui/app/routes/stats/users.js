import classic from 'ember-classic-decorator';

import Base from './base';

@classic
export default class UsersRoute extends Base {
  queryParams = {
    date_range: {
      refreshModel: true,
    },
    start_at: {
      refreshModel: true,
    },
    end_at: {
      refreshModel: true,
    },
    query: {
      refreshModel: true,
    },
    search: {
      refreshModel: true,
    },
  };

  model() {
    return {};
  }
}
